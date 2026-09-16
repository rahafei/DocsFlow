class OnboardingItem {
  final String logoImage;
  final String mainImage;
  final String title;
  final String description;

  const OnboardingItem({
    required this.logoImage,
    required this.mainImage,
    required this.title,
    required this.description,
  });
}

const List<OnboardingItem> onboardingItems = [
  OnboardingItem(
    logoImage: 'assets/images/scan.png',
    mainImage: 'assets/images/scanner.png',
    title: 'طريقة بسيطة للمسح الضوئي',
    description:
        'حوّل مستنداتك المكتوبة بخط اليد إلى ملفات رقمية بسهولة.',
  ),
  OnboardingItem(
    logoImage: 'assets/images/folder.png',
    mainImage: 'assets/images/man.png',
    title: 'تنظيم ملفاتك بلمسة',
    description:
        'رتّب مستنداتك واحفظها بسهولة لتصل إليها وقتما تشاء.',
  ),
  OnboardingItem(
    logoImage: 'assets/images/security.png',
    mainImage: 'assets/images/shield.png',
    title: 'أمن ومحمي تمامًا',
    description:
        'نحرص على أمان ملفاتك وبياناتك ونحافظ على خصوصيتها.',
  ),
];