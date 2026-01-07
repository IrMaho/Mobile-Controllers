import 'dart:io';

import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../input_capture/presentation/cubit/input_capture_cubit.dart';
import '../../../input_capture/data/sources/android_input_receiver.dart';
import '../../../input_capture/data/sources/accessibility_helper.dart';
import '../cubit/connection_cubit.dart';

class ConnectionPage extends StatelessWidget {
  const ConnectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => getIt<ConnectionCubit>()),
        BlocProvider(create: (context) => getIt<InputCaptureCubit>()),
      ],
      child: const ConnectionView(),
    );
  }
}

class ConnectionView extends StatefulWidget {
  const ConnectionView({super.key});

  @override
  State<ConnectionView> createState() => _ConnectionViewState();
}

class _ConnectionViewState extends State<ConnectionView> {
  final TextEditingController _portController = TextEditingController(
    text: '5000',
  );
  final TextEditingController _ipController = TextEditingController(
    text: '192.168.1.100',
  );

  final AndroidInputReceiver _inputReceiver = AndroidInputReceiver();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Listener will be set up in BlocConsumer when connected
  }

  void _setupDataListener() {
    // Get repository directly
    final repo = context
        .read<ConnectionCubit>()
        .listenConnectionStatus
        .repository;

    // Listen to incoming data (Android side)
    repo.onDataReceived.listen((data) {
      debugPrint('📱 Received ${data.length} bytes');
      _inputReceiver.handleInputData(data);
    });

    debugPrint('✅ Data listener set up on Android');
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    return Scaffold(
      appBar: AppBar(title: const Text('Device Connection')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocConsumer<ConnectionCubit, ConnectionState>(
          listener: (context, state) {
            if (state is ConnectionError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }

            // Initialize input capture when connected (Desktop only)
            if (state is ConnectionConnected && isDesktop) {
              context.read<InputCaptureCubit>().initialize();
            }

            // Setup data listener when connected (Android only)
            if (state is ConnectionConnected && !isDesktop) {
              _setupDataListener();
            }

            // Cleanup on disconnect
            if (state is ConnectionInitial && isDesktop) {
              context.read<InputCaptureCubit>().stop();
            }
          },
          builder: (context, state) {
            if (state is ConnectionConnected) {
              return _buildConnectedView(context, isDesktop);
            }

            if (isDesktop) {
              return _buildDesktopView(context, state);
            } else {
              return _buildMobileView(context, state);
            }
          },
        ),
      ),
    );
  }

  Widget _buildConnectedView(BuildContext context, bool isDesktop) {
    if (isDesktop) {
      // Desktop: Show capture status
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text('Connected to Phone!', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 16),
            BlocBuilder<InputCaptureCubit, InputCaptureState>(
              builder: (context, captureState) {
                String status = 'Monitoring...';
                Color statusColor = Colors.blue;

                if (captureState is InputCaptureActive) {
                  status = '🎮 CONTROLLING PHONE';
                  statusColor = Colors.orange;
                } else if (captureState is InputCaptureMonitoring) {
                  status = '👀 Move mouse to RIGHT edge →';
                  statusColor = Colors.green;
                }

                return Column(
                  children: [
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 18,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Move to LEFT edge or press ESC to return to PC',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                context.read<ConnectionCubit>().disconnect();
              },
              child: const Text('Disconnect'),
            ),
          ],
        ),
      );
    } else {
      // Android: Show status
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text('Connected!', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            const Text('Waiting for input from PC...'),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                context.read<ConnectionCubit>().disconnect();
              },
              child: const Text('Disconnect'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDesktopView(BuildContext context, ConnectionState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Status: ${state.runtimeType}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Scan for Devices'),
          onPressed: () {
            context.read<ConnectionCubit>().startScan();
          },
        ),
        const SizedBox(height: 20),
        if (state is ConnectionScanning) const LinearProgressIndicator(),

        if (state is ConnectionDiscovered) ...[
          const Text(
            'Found Devices:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: state.devices.length,
              itemBuilder: (context, index) {
                final device = state.devices[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.phone_android),
                    title: Text(device.name),
                    subtitle: Text('${device.ip}:${device.port}'),
                    trailing: ElevatedButton(
                      child: const Text('Connect'),
                      onPressed: () {
                        context.read<ConnectionCubit>().connect(
                          device.ip,
                          device.port,
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],

        ExpansionTile(
          title: const Text("Manual Connection"),
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _ipController,
                decoration: const InputDecoration(labelText: "IP Address"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                child: const Text("Connect Manually"),
                onPressed: () {
                  context.read<ConnectionCubit>().connect(
                    _ipController.text,
                    5000,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileView(BuildContext context, ConnectionState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_tethering, size: 64, color: Colors.blue),
          const SizedBox(height: 20),
          const Text(
            '1. Enable Accessibility Service (tap below)\n'
            '2. Enable USB Tethering or Wi-Fi.\n'
            '3. Start Server.\n'
            '4. Use PC app to connect.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.accessibility),
            label: const Text('Enable Mouse Control'),
            onPressed: () {
              AccessibilityHelper.openAccessibilitySettings();
            },
          ),
          const SizedBox(height: 30),
          if (state is ConnectionLoading)
            const CircularProgressIndicator()
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              onPressed: () {
                final port = int.tryParse(_portController.text) ?? 5000;
                context.read<ConnectionCubit>().startServer(port);
              },
              child: const Text('Start Server & Advertise'),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
}
