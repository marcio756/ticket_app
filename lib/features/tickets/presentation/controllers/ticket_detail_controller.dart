import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/ticket_remote_datasource.dart';
import '../../data/models/ticket_model.dart';
import '../../../../core/network/api_client.dart';

// State to hold the ticket and any UI temporary states if needed
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

  /// Adds a message, optionally with an attachment
  Future<bool> addMessage(String text, {File? attachment}) async {
    try {
      if (text.isEmpty && attachment == null) return false;

      // Optimistic update or waiting for response depends on preference.
      // Here we wait to ensure upload success.
      final newMessage = await _datasource.addMessage(ticketId, text, attachment: attachment);
      
      // Update local state with the new message
      state.whenData((ticket) {
        if (ticket != null) {
          final updatedMessages = [...ticket.messages, newMessage];
          // Re-sort if necessary, assuming backend returns correct order
          updatedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          
          state = AsyncValue.data(ticket.copyWith(messages: updatedMessages));
        }
      });
      return true;
    } catch (e) {
      // Log error
      return false;
    }
  }

  Future<bool> assignToMe() async {
    try {
      final success = await _datasource.assignTicketToMe(ticketId);
      if (success) {
        await _loadTicket(); // Reload to get updated assignee
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Helper to pick a file
  Future<File?> pickAttachment() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Allow any file type (.exe, .mp4, etc.)
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      // Handle permission errors or picker errors
      return null;
    }
  }
}

final ticketDetailControllerProvider = StateNotifierProvider.family<TicketDetailController, AsyncValue<TicketModel?>, int>((ref, ticketId) {
  final client = ref.watch(apiClientProvider);
  final datasource = TicketRemoteDatasource(client);
  return TicketDetailController(datasource, ticketId);
});