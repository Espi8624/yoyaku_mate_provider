import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sign_up_page.dart';
import 'package:provider/provider.dart';
import 'services/sign_in_service.dart';
import 'user_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  bool _isLoading = false;
  String? _errorMsg;

  Future<void> _tryLogin() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      await loginAndFetchUserInfo(
        _idController.text.trim(),
        _pwController.text,
        (userInfo) async {
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          userProvider.setUserInfo(userInfo);
          final userId = userInfo['data']['_id'] ?? userInfo['data']['id'];

          // store_info 조회 (최대 3번 재시도)
          int retries = 0;
          bool storeFetched = false;
          Map<String, dynamic>? storeInfo;
          while (retries < 3 && !storeFetched) {
            try {
              final storeResponse = await http.get(
                Uri.parse('http://localhost:8080/api/provider_store?user_id=$userId'),
                headers: {'Authorization': 'Bearer ${await FirebaseAuth.instance.currentUser!.getIdToken(true)}'},
              );
              if (storeResponse.statusCode == 200) {
                storeInfo = jsonDecode(storeResponse.body);
                storeFetched = true;
              } else {
                throw Exception('Store info fetch failed: ${storeResponse.statusCode}');
              }
            } catch (e) {
              retries++;
              if (retries < 3) {
                await Future.delayed(const Duration(milliseconds: 500));
              }
            }
          }
          if (!storeFetched) {
            throw Exception('가게 정보 조회 실패');
          }

          userProvider.setStoreInfo(storeInfo!);

          // 로그인 성공
          if (mounted) {
            widget.onLoginSuccess();
            Navigator.of(context).pushReplacementNamed('/');
          }
        },
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMsg = e.message ?? 'IDまたはパスワードが正しくありません。';
      });
    } catch (e) {
      setState(() {
        _errorMsg = '로그인 실패: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 360,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'ログイン',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF263238),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _idController,
                  decoration: InputDecoration(
                    labelText: 'メールアドレス',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _pwController,
                  decoration: InputDecoration(
                    labelText: 'パスワード',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                ),
                if (_errorMsg != null) ...[
                  const SizedBox(height: 16),
                  Text(_errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 14), textAlign: TextAlign.center),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6F61),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isLoading ? null : _tryLogin,
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('ログイン'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SignUpPage()),
                      );
                    },
                    child: const Text('まだアカウントを持っていませんか？'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}