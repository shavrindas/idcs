// 경로: lib/pages/common/find_id_page.dart
import 'package:flutter/material.dart';
import 'package:idcs/components/common/find_id/find_id_components.dart';
import 'package:idcs/services/common/find_id/auth_api_service.dart';
import '../../services/common/api_client.dart';
import 'package:idcs/l10n/l10n_context.dart';
import 'package:idcs/components/shared/app_toast.dart';

class FindIdPage extends StatefulWidget {
  const FindIdPage({super.key});

  @override
  State<FindIdPage> createState() => _FindIdPageState();
}

class _FindIdPageState extends State<FindIdPage> {
  final TextEditingController _emailController = TextEditingController();

  bool _isExpanded = false;
  String _resultMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckAccount() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      AppToast.warning(context, context.l10n.findIdEmailRequired);
      return;
    }

    try {
      final result = await AuthApiService.checkAccountExistence(email);

      setState(() {
        _isExpanded = true;
        _resultMessage = result['message'];
      });

    } catch (e) {
      setState(() {
        _isExpanded = true;
        _resultMessage = context.l10n.errorOccurred(describeApiError(context, e));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(context.l10n.findId, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                context.l10n.findIdSubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              FindIdBox(
                emailController: _emailController,
                onSubmit: _handleCheckAccount,
                resultMessage: _resultMessage,
                isExpanded: _isExpanded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
