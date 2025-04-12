import 'package:finmate/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color4, Colors.white],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animation
              Lottie.network(
                'https://assets5.lottiefiles.com/packages/lf20_ikaawl5v.json', // Money/finance animation
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),

              const SizedBox(height: 30),

              // App name with modern typography
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [color2, color3],
                ).createShader(bounds),
                child: Text(
                  "FINMATE",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Tagline with improved typography
              Text(
                "Your Personal Finance Companion",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color2.withAlpha(204), // Changed from withOpacity(0.8)
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 50),

              // Animated loading indicator
              Container(
                width: 220,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Progress indicator with modern look
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1500),
                      builder: (context, double value, child) {
                        return Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: value,
                                minHeight: 8,
                                backgroundColor: Colors.grey.shade200,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(color3),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Loading text with fade animation
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, double value, child) {
                        return Opacity(
                          opacity: value,
                          child: Text(
                            "Setting up your financial dashboard...",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: color1.withAlpha(
                                  179), // Changed from withOpacity(0.7)
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;
  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color4,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 70,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 20),
              Text(
                "Oops! Something went wrong",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                error,
                style: TextStyle(
                  fontSize: 14,
                  color: color2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color3,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Go Back",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
