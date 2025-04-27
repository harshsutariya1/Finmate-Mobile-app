import 'package:finmate/constants/assets.dart';
import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/screens/auth/auth.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntroSlider extends StatefulWidget {
  const IntroSlider({super.key});

  @override
  State<IntroSlider> createState() => _IntroSliderState();
}

class _IntroSliderState extends State<IntroSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<IntroSlide> _slides = [
    IntroSlide(
      image: introImage1,
      title: "Welcome to FinMate",
      description:
          "Your personal finance companion for managing money, tracking expenses, and achieving financial freedom.",
    ),
    IntroSlide(
      image: introImage2,
      title: "Track Your Expenses",
      description:
          "Easily record and categorize your daily expenses to understand your spending habits.",
    ),
    IntroSlide(
      image: introImage3,
      title: "Set Financial Goals",
      description:
          "Create personal financial goals and track your progress to secure your future.",
    ),
    IntroSlide(
      image: introImage4,
      title: "Group Expenses",
      description:
          "Split bills and manage shared expenses with friends, family, or roommates effortlessly.",
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _markIntroAsShown() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenIntro', true);
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishIntro();
    }
  }

  void _finishIntro() {
    _markIntroAsShown();
    Navigate().toAndRemoveUntil(const AuthScreen());
  }

  @override
  Widget build(BuildContext context) {
    bool isLastIntro = _currentPage == _slides.length - 1;
    return Scaffold(
      backgroundColor: color4,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _finishIntro,
                  child: Text(
                    "Skip",
                    style: TextStyle(
                      color: color3,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // Slides content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return _buildSlide(slide);
                },
              ),
            ),

            // Next/Done button container - removed indicators from here
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.end, // Changed to end alignment
                children: [
                  // Next/Done button
                  (isLastIntro)
                      ? Expanded(
                          // Wrap with Expanded to take available width
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  color2, // Changed background color
                              foregroundColor: whiteColor,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    30), // Changed border radius
                              ),
                              elevation: 2,
                            ),
                            onPressed: _finishIntro,
                            child: Row(
                              // Use Row to include text and icon
                              mainAxisAlignment: MainAxisAlignment
                                  .center, // Center content in the expanded button
                              children: [
                                Text(
                                  "Get Started",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                sbw20,
                                const Icon(
                                  Icons
                                      .arrow_forward_ios, // Added iOS arrow icon
                                  size: 20, // Adjust icon size as needed
                                  color: color3,
                                ),
                                sbw20,
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 20,
                                  color: color3.withAlpha(180),
                                ),
                                sbw20,
                                 Icon(
                                  Icons
                                      .arrow_forward_ios, // Added iOS arrow icon
                                  size: 20, // Adjust icon size as needed
                                  color: color3.withAlpha(70),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color2, // Changed background color
                            foregroundColor: whiteColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  10), // Changed border radius
                            ),
                            elevation: 2,
                          ),
                          onPressed: _nextPage,
                          child: Row(
                            // Use Row to include text and icon
                            mainAxisSize:
                                MainAxisSize.min, // Keep button size compact
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Next",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              sbw5,
                              const Icon(
                                Icons.arrow_forward_ios, // Added iOS arrow icon
                                size: 20, // Adjust icon size as needed
                                color: color3,
                              ),
                            ],
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(IntroSlide slide) {
    bool isFirstSlide = _currentPage == 0;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image
          Image.asset(
            slide.image,
            width: MediaQuery.sizeOf(context).width,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),

          // Indicator row that takes full width
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: List.generate(
                _slides.length,
                (index) {
                  final bool isActive = _currentPage == index;
                  // Each indicator gets an Expanded widget to fill width
                  if (isActive) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      child: _buildIndicator(index),
                    );
                  } else {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        child: _buildIndicator(index),
                      ),
                    );
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Title
          (isFirstSlide)
              ? Column(
                  children: [
                    // "welcome to" text
                    Text(
                      "welcome to",
                      style: TextStyle(
                        color: color2,
                        fontSize: 24,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // "FINMATE" text with gradient
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [color3, color2],
                        stops: const [
                          0.5,
                          1.0
                        ], // color3 takes 60% of the gradient
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        "FINMATE",
                        style: TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                          color: Colors
                              .white, // The ShaderMask requires white as base color
                        ),
                      ),
                    ),
                  ],
                )
              : Text(
                  slide.title,
                  style: TextStyle(
                    color: color2,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3, // Limit to 3 lines
                  softWrap: true, // Allow wrapping
                ),
          const SizedBox(height: 16),

          // Description
          Text(
            slide.description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 3, // Limit to 3 lines
            softWrap: true, // Allow wrapping
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(int index) {
    final bool isActive = _currentPage == index;

    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? color3 : Colors.grey.withAlpha(80),
        borderRadius: BorderRadius.circular(isActive ? 8 : 4),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color3.withAlpha(100),
                  blurRadius: 3,
                  spreadRadius: 0.5,
                )
              ]
            : null,
      ),
      // Make active indicator a dot, inactive ones fill the space
      width: isActive ? 40 : double.infinity,
    );
  }
}

class IntroSlide {
  final String image;
  final String title;
  final String description;

  IntroSlide({
    required this.image,
    required this.title,
    required this.description,
  });
}
