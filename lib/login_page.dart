import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  bool _isLoading = false;
  String? _errorMsg;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _tryLogin() async {
    FocusScope.of(context).unfocus();
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _idController.text.trim(),
        password: _pwController.text,
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          if (e.code == 'user-not-found' ||
              e.code == 'wrong-password' ||
              e.code == 'invalid-credential') {
            _errorMsg = 'メールアドレス、またはパスワードが正しくありません。';
          } else {
            _errorMsg = 'ログインに失敗しました。時間をおいて再度お試しください。';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = '予期せぬエラーが発生しました。';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToLoginView() {
    _pageController.animateToPage(1,
        duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  void _navigateToWelcomeView() {
    setState(() {
      _errorMsg = null;
    });
    _pageController.animateToPage(0,
        duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildWelcomeView(context),
          _buildLoginView(context),
        ],
      ),
    );
  }

  //　Welcomeページ
  Widget _buildWelcomeView(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isLandscape ? 64.0 : 32.0,
              vertical: isLandscape ? 16.0 : 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/app_icon.png',
                        width: isLandscape ? 32 : 40,
                        height: isLandscape ? 32 : 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'ルスイ',
                      style: TextStyle(
                        fontSize: isLandscape ? 16 : 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentPrimary,
                      ),
                    ),
                  ],
                ),
                // 上段コンテンツをグループ化
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('おかえりなさい。',
                        style: TextStyle(
                            fontSize: isLandscape ? 28 : 36,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                            color: AppColors.textPrimary)),
                    SizedBox(height: isLandscape ? 8 : 12),
                    const Text('最善を尽くして店舗管理を補助致します！',
                        style: TextStyle(
                            fontSize: 16, color: AppColors.textSecondary)),
                  ],
                ),
                // 下段のボタンをグループ化
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: _navigateToLoginView,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: const Text('ログイン',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => GoRouter.of(context).push('/signup'),
                      child: const Text('アカウント作成',
                          style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ログイン入力画面
  Widget _buildLoginView(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: screenHeight - MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isLandscape ? 64.0 : 32.0,
              vertical: isLandscape ? 16.0 : 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 上段グループ
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: _navigateToWelcomeView,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, size: 18),
                      ),
                    ),
                    SizedBox(height: isLandscape ? 20 : 40),
                    Text('本日もよろしくお願いします！',
                        style: TextStyle(
                            fontSize: isLandscape ? 16 : 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    const Text('メールアドレスとパスワードを入力してください。',
                        style: TextStyle(
                            fontSize: 15, color: AppColors.textSecondary)),
                  ],
                ),

                // 中央グループ
                Column(
                  children: [
                    // 横モードで余白設定
                    if (isLandscape) const SizedBox(height: 12),
                    TextFormField(
                      controller: _idController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: 'メールアドレス',
                        filled: true,
                        fillColor: AppColors.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.accentPrimary, width: 2),
                        ),
                      ),
                    ),
                    SizedBox(height: isLandscape ? 20 : 24),
                    TextFormField(
                      controller: _pwController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _tryLogin(),
                      decoration: InputDecoration(
                        labelText: 'パスワード',
                        filled: true,
                        fillColor: AppColors.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.accentPrimary, width: 2),
                        ),
                      ),
                    ),
                    if (_errorMsg != null)
                      Padding(
                        padding:
                            EdgeInsets.only(top: isLandscape ? 16.0 : 24.0),
                        child: Text(_errorMsg!,
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 14)),
                      ),
                  ],
                ),

                // 下段グループ
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 横モードで追加間隔
                    if (isLandscape) const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _tryLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ))
                          : const Text('ログイン',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ForgotPasswordPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'パスワードを忘れましたか？',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
