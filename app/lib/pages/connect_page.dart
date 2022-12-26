import "package:flutter/material.dart" hide Page;
import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:google_fonts/google_fonts.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:rive/rive.dart";
import "package:socket_io_client/socket_io_client.dart";
import "package:typewriter/app_router.dart";
import "package:typewriter/hooks/delayed_execution.dart";
import "package:typewriter/main.dart";
import "package:typewriter/models/book.dart";
import "package:typewriter/widgets/filled_button.dart";
import "package:typewriter/widgets/text_scroller.dart";

final socketProvider = StateNotifierProvider<SocketNotifier, Socket?>(SocketNotifier.new);

class SocketNotifier extends StateNotifier<Socket?> {
  SocketNotifier(this.ref) : super(null);

  final StateNotifierProviderRef<SocketNotifier, Socket?> ref;

  void init(String hostname, int port) {
    if (state != null) return;
    debugPrint("Initializing socket");
    final socket =
        io("http://$hostname:$port", OptionBuilder().setTransports(["websocket"]).disableAutoConnect().build());

    socket
      ..onConnect((_) {
        debugPrint("connected");
        state = socket;
        setup(socket);
      })
      ..onConnectError((data) {
        debugPrint("connect error $data");
        if (state?.connected ?? false) state?.dispose();
        state = null;
        ref.read(appRouter).replaceAll([ErrorConnectRoute(hostname: hostname, port: port)]);
      })
      ..onConnectTimeout((data) {
        debugPrint("connect timeout $data");
        if (state?.connected ?? false) state?.dispose();
        state = null;
        ref.read(appRouter).replaceAll([ErrorConnectRoute(hostname: hostname, port: port)]);
      })
      ..onError((data) {
        debugPrint("error $data");
        if (state?.connected ?? false) state?.dispose();
        state = null;
        ref.read(appRouter).replaceAll([ErrorConnectRoute(hostname: hostname, port: port)]);
      })
      ..onDisconnect((_) {
        debugPrint("disconnected");
        state = null;
        ref.read(appRouter).replaceAll([const HomeRoute()]);
      })
      ..connect();
  }

  Future<void> setup(Socket socket) async {
    await ref.read(bookProvider.notifier).fetchBook();
    await ref.read(appRouter).push(const BookRoute());
  }

  @override
  void dispose() {
    state?.dispose();
    super.dispose();
  }
}

class ConnectPage extends HookConsumerWidget {
  const ConnectPage({required this.hostname, required this.port, super.key});

  final String hostname;
  final int port;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useDelayedExecution(() => ref.read(socketProvider.notifier).init(hostname, port));

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          const Expanded(
            flex: 8,
            child: RiveAnimation.asset(
              "assets/tour.riv",
              stateMachines: ["state_machine"],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Waiting for connection",
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),
          TextScroller(
            texts: [
              "Establishing interstellar connection",
              "Tuning communication frequency",
              "Initiating communication protocol",
              "Negotiating connection parameters",
              "Analyzing network traffic",
              "Establishing telepathic link",
              "Activating quantum communication",
              "Setting up virtual private connection",
              "Checking for network interference",
              "Hacking into the Matrix",
              "Summoning the interdimensional portal",
              "Opening the gateway to the astral plane",
              "Establishing connection to the other side",
              "Connecting to the cosmic mind",
              "Contacting extraterrestrial intelligence",
              "Dialing up the time-space continuum",
              "Downloading thoughts from the future",
              "Establishing link to parallel universe",
              "Establishing link to the universal consciousness",
              "Tuning into the cosmic frequency",
              "Initiating intergalactic communication",
              "Bending the fabric of reality",
              "Syncing with the cosmic clock",
              "Activating the trans-dimensional relay",
              "Establishing telekinetic connection",
              "Channeling the universal energy",
              "Unlocking the secrets of the universe",
              "Contacting the all-seeing eye",
              "Teleporting through time and space",
              "Tuning into the higher dimensions",
              "Connecting to the great beyond",
              "Downloading knowledge from the Akashic Records",
              "Establishing a psychic link",
              "Activating the cosmic gateway",
              "Syncing with the universe's frequency",
              "Tuning into the cosmic vibration",
              "Connecting to the quantum field",
              "Establishing a connection to the divine",
              "Channeling the universal wisdom",
            ]..shuffle(),
            style: GoogleFonts.jetBrainsMono(fontSize: 20, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const Spacer(),
        ],
      ),
    );
  }
}

class ErrorConnectPage extends HookConsumerWidget {
  const ErrorConnectPage({required this.hostname, required this.port, super.key});

  final String hostname;
  final int port;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          const Expanded(
            flex: 6,
            child: MouseRegion(
              cursor: SystemMouseCursors.zoomIn,
              child: RiveAnimation.asset(
                "assets/robot_island.riv",
                stateMachines: ["Motion"],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Communication error",
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          Text(
            "There was an error while communicating to the server.\nPlease check your connection and try again.",
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(fontSize: 20, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(FontAwesomeIcons.repeat),
            label: const Text("Reconnect"),
            onPressed: () {
              ref.read(appRouter).replaceAll([ConnectRoute(hostname: hostname, port: port)]);
            },
          ),
          const SizedBox(height: 24),
          const Spacer(),
        ],
      ),
    );
  }
}
