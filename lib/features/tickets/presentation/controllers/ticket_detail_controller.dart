import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/ticket_remote_datasource.dart';
import '../../data/models/ticket_model.dart';

// Estado do ecrã de detalhe
class TicketDetailState {
  final AsyncValue<TicketModel> ticket;
  final bool isSending; // Para mostrar loading no botão de enviar
  final File? selectedAttachment; // Ficheiro selecionado para envio

  TicketDetailState({
    required this.ticket,
    this.isSending = false,
    this.selectedAttachment,
  });

  TicketDetailState copyWith({
    AsyncValue<TicketModel>? ticket,
    bool? isSending,
    File? selectedAttachment,
  }) {
    return TicketDetailState(
      ticket: ticket ?? this.ticket,
      isSending: isSending ?? this.isSending,
      selectedAttachment: selectedAttachment ?? this.selectedAttachment,
    );
  }
}

// Controller Family: Recebe o ID do ticket como parâmetro
final ticketDetailControllerProvider = StateNotifierProvider.family.autoDispose<TicketDetailController, TicketDetailState, int>((ref, ticketId) {
  return TicketDetailController(ticketId, TicketRemoteDataSource());
});

class TicketDetailController extends StateNotifier<TicketDetailState> {
  final int ticketId;
  final TicketRemoteDataSource _dataSource;

  TicketDetailController(this.ticketId, this._dataSource)
      : super(TicketDetailState(ticket: const AsyncValue.loading())) {
    loadTicket();
  }

  Future<void> loadTicket() async {
    try {
      final ticket = await _dataSource.getTicketDetails(ticketId);
      state = state.copyWith(ticket: AsyncValue.data(ticket));
    } catch (e, stack) {
      state = state.copyWith(ticket: AsyncValue.error(e, stack));
    }
  }

  // Selecionar anexo
  Future<void> pickAttachment() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      state = state.copyWith(selectedAttachment: File(result.files.single.path!));
    }
  }

  // Limpar anexo
  void clearAttachment() {
    state = state.copyWith(selectedAttachment: null); // Passa null explicitamente? Não, no Dart copyWith precisa de lógica extra para null.
    // Hack rápido para o copyWith simples: recriar o estado.
    state = TicketDetailState(
      ticket: state.ticket,
      isSending: state.isSending,
      selectedAttachment: null,
    );
  }

  // Enviar mensagem
  Future<bool> sendMessage(String message) async {
    if (message.isEmpty && state.selectedAttachment == null) return false;

    state = state.copyWith(isSending: true);

    try {
      await _dataSource.sendMessage(
        ticketId,
        message,
        state.selectedAttachment,
      );

      // Atualizar a lista de mensagens localmente (Optimistic Update ou Re-fetch)
      // Aqui vamos adicionar a mensagem à lista existente no TicketModel se possível
      // Como o TicketModel pode não ter lista de mensagens mutável, o ideal é recarregar
      await loadTicket(); 
      
      clearAttachment();
      state = state.copyWith(isSending: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSending: false);
      return false;
    }
  }
}