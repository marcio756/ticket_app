import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/ticket_remote_datasource.dart';
import '../../data/models/ticket_model.dart';
import '../../../../core/network/api_client.dart';

class TicketDetailController extends StateNotifier<AsyncValue<TicketModel?>> {
  final TicketRemoteDatasource _datasource;
  final int ticketId;

  TicketDetailController(this._datasource, this.ticketId) : super(const AsyncValue.loading()) {
    _loadTicket();
  }

  Future<void> _loadTicket() async {
    try {
      final ticket = await _datasource.getTicket(ticketId);
      state = AsyncValue.data(ticket);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// [ATUALIZADO] Envia o tracking e atualiza o estado localmente
  Future<void> trackTime() async {
    // 1. Envia sinal à API
    final newTime = await _datasource.trackSupportTime(ticketId, 30);
    
    // 2. Se a API retornou o novo tempo com sucesso, atualizamos o estado local
    if (newTime != null) {
      state.whenData((ticket) {
        if (ticket != null && ticket.user != null) {
          // Cria uma cópia do ticket com o user atualizado
          final updatedUser = ticket.user!.copyWith(dailySupportSeconds: newTime);
          final updatedTicket = ticket.copyWith(user: updatedUser);
          
          // Atualiza o estado sem recarregar a página toda
          state = AsyncValue.data(updatedTicket);
        }
      });
    }
  }

  Future<bool> addMessage(String text, {File? attachment}) async {
    try {
      if (text.isEmpty && attachment == null) return false;

      final newMessage = await _datasource.addMessage(ticketId, text, attachment: attachment);
      
      state.whenData((ticket) {
        if (ticket != null) {
          final updatedMessages = [...ticket.messages, newMessage];
          // Ordenar se necessário
          updatedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          
          state = AsyncValue.data(ticket.copyWith(messages: updatedMessages));
        }
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> assignToMe() async {
    try {
      final success = await _datasource.assignTicketToMe(ticketId);
      if (success) {
        await _loadTicket(); 
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<File?> pickAttachment() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

final ticketDetailControllerProvider = StateNotifierProvider.family<TicketDetailController, AsyncValue<TicketModel?>, int>((ref, ticketId) {
  final client = ref.watch(apiClientProvider);
  final datasource = TicketRemoteDatasource(client);
  return TicketDetailController(datasource, ticketId);
});