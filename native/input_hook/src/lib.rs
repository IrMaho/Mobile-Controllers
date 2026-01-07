use std::ffi::{c_int, c_void}; // Keeping c_int/c_void as they might be used in external signatures or callbacks
use std::sync::atomic::{AtomicBool, Ordering};
use std::thread;

use windows::Win32::Foundation::{HINSTANCE, LPARAM, LRESULT, WPARAM};
use windows::Win32::UI::WindowsAndMessaging::{
    CallNextHookEx, GetMessageW, SetWindowsHookExW, UnhookWindowsHookEx, HHOOK, MSG, WH_MOUSE_LL,
    WM_MOUSEMOVE, WM_LBUTTONDOWN, WM_LBUTTONUP, WM_RBUTTONDOWN, WM_RBUTTONUP, SetCursorPos,
    MSLLHOOKSTRUCT,
};
// Removed KeyboardAndMouse import as MSLLHOOKSTRUCT is now above

static IS_CAPTURING: AtomicBool = AtomicBool::new(false);
static mut HOOK_HANDLE: HHOOK = HHOOK(0);
static mut DART_CALLBACK: Option<extern "C" fn(i32, i32, i32)> = None;

// Event Types for Callback
const EVENT_MOVE: i32 = 0;
const EVENT_DOWN: i32 = 1;
const EVENT_UP: i32 = 2;

#[no_mangle]
pub extern "C" fn remote_set_cursor_pos(x: i32, y: i32) {
    unsafe {
        SetCursorPos(x, y);
    }
}

#[no_mangle]
pub extern "C" fn set_capturing(capturing: bool) {
    IS_CAPTURING.store(capturing, Ordering::SeqCst);
}

#[no_mangle]
pub extern "C" fn set_callback(callback: extern "C" fn(i32, i32, i32)) {
    unsafe {
        DART_CALLBACK = Some(callback);
    }
}

#[no_mangle]
pub extern "C" fn start_hook() {
    thread::spawn(|| unsafe {
        let hook = SetWindowsHookExW(
            WH_MOUSE_LL,
            Some(mouse_hook_proc),
            HINSTANCE(0),
            0,
        );

        if let Ok(h) = hook {
            HOOK_HANDLE = h;
            let mut msg = MSG::default();
            while GetMessageW(&mut msg, None, 0, 0).as_bool() {
                // Process messages
            }
            UnhookWindowsHookEx(HOOK_HANDLE);
        }
    });
}

unsafe extern "system" fn mouse_hook_proc(code: i32, wparam: WPARAM, lparam: LPARAM) -> LRESULT {
    if code >= 0 {
        let capture = IS_CAPTURING.load(Ordering::SeqCst);
        
        let p_struct = &*(lparam.0 as *const MSLLHOOKSTRUCT);
        let x = p_struct.pt.x;
        let y = p_struct.pt.y;
        let msg = wparam.0 as u32;

        if capture {
             // If capturing, we might want to block (return 1)
             // And send delta or absolute to Dart
             
             // Map Windows Message to Simple ID
             let event_type = match msg {
                 WM_MOUSEMOVE => EVENT_MOVE,
                 WM_LBUTTONDOWN | WM_RBUTTONDOWN => EVENT_DOWN,
                 WM_LBUTTONUP | WM_RBUTTONUP => EVENT_UP,
                 _ => -1,
             };

             if let Some(cb) = DART_CALLBACK {
                 if event_type != -1 {
                    cb(event_type, x, y);
                 }
             }

             // Swallow event if capturing (Return 1)
             // EXCEPT: We might want to allow some hotkey to escape?
             // For now, simple swallow.
             return LRESULT(1);
        } else {
            // Monitor for edge detection (Passively)
            // Ideally we also send this to Dart to decide IF we should start capturing
             if let Some(cb) = DART_CALLBACK {
                 // Send passive move (type 0)
                  if msg == WM_MOUSEMOVE {
                     cb(EVENT_MOVE, x, y);
                  }
             }
        }
    }
    CallNextHookEx(HOOK_HANDLE, code, wparam, lparam)
}
