import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_provider.dart';
import '../state/my_requests_provider.dart';
import '../widgets/seat_request_card.dart';

/// Minhas solicitações. A lista se atualiza sozinha quando o motorista aceita
/// ou recusa (evento via WebSocket → provider → rebuild).
class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  void _reload() {
    final user = context.read<AuthProvider>().user;
    if (user != null) context.read<MyRequestsProvider>().load(user.id);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MyRequestsProvider>();

    // Quando chega um evento em tempo real, mostra um aviso e limpa o flag.
    if (p.lastEventMessage != null) {
      final message = p.lastEventMessage!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🔔 $message'), backgroundColor: Colors.indigo),
        );
        context.read<MyRequestsProvider>().clearBanner();
      });
    }

    if (p.loading && p.requests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: p.requests.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 160),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_seat_outlined, size: 56, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Você ainda não solicitou vagas.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: p.requests.length,
              itemBuilder: (_, i) => SeatRequestCard(request: p.requests[i]),
            ),
    );
  }
}
