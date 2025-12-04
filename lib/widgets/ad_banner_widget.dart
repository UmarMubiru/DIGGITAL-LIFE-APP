// lib/widgets/ad_banner_widget.dart

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  // 1. State variables for the ad
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  // Use Google's public test ID for banners
  final String _adUnitId = "ca-app-pub-3940256099942544/6300978111";

  @override
  void initState() {
    super.initState();
    _loadAd(); // 2. Load the ad as soon as the widget is created
  }

  @override
  void dispose() {
    _bannerAd?.dispose(); // 3. Clean up the ad when the widget is removed
    super.dispose();
  }

  // 4. The core ad-loading logic
  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        // Called when an ad is successfully received.
        onAdLoaded: (ad) {
          debugPrint('$ad loaded.');
          setState(() {
            _isAdLoaded = true;
          });
        },
        // Called when an ad request failed.
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          // Dispose the ad to free up resources.
          ad.dispose();
        },
      ),
    )..load(); // The '..' (cascade operator) calls load() on the BannerAd instance
  }

  // 5. The build method that decides what to show
  @override
  Widget build(BuildContext context) {
    if (_isAdLoaded && _bannerAd != null) {
      // If the ad is loaded, show it
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    } else {
      // If the ad is not loaded yet, show a placeholder
      // This is the same size as a standard banner ad.
      return const SizedBox(
        width: 320,
        height: 50,
        child: Center(
          child: Text("Ad is loading..."),
        ),
      );
    }
  }
}
