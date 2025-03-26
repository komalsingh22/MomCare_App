import 'package:flutter/material.dart';
import 'package:health_app/theme/app_theme.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({Key? key}) : super(key: key);

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final List<HealthResource> _articles = [
    HealthResource(
      title: 'Nutrition During Pregnancy',
      category: 'Nutrition',
      imageUrl: 'assets/images/nutrition.jpg',
      source: 'WHO Maternal Health',
      isSaved: true,
      publishDate: DateTime.now().subtract(const Duration(days: 7)),
    ),
    HealthResource(
      title: 'Managing Pregnancy Discomfort',
      category: 'Wellness',
      imageUrl: 'assets/images/wellness.jpg',
      source: 'American Pregnancy Association',
      isSaved: false,
      publishDate: DateTime.now().subtract(const Duration(days: 14)),
    ),
    HealthResource(
      title: 'Safe Exercises During Pregnancy',
      category: 'Fitness',
      imageUrl: 'assets/images/fitness.jpg',
      source: 'Mayo Clinic',
      isSaved: false,
      publishDate: DateTime.now().subtract(const Duration(days: 3)),
    ),
    HealthResource(
      title: 'Understanding Prenatal Tests',
      category: 'Medical',
      imageUrl: 'assets/images/medical.jpg',
      source: 'CDC Pregnancy',
      isSaved: true,
      publishDate: DateTime.now().subtract(const Duration(days: 21)),
    ),
  ];
  
  final List<Contact> _contacts = [
    Contact(
      name: 'Dr. Sarah Johnson',
      role: 'OB/GYN',
      phone: '+1 (555) 123-4567',
      email: 'sarah.johnson@example.com',
      address: '123 Healthcare Ave, Medical Center',
      isFavorite: true,
    ),
    Contact(
      name: 'City Hospital Maternity',
      role: 'Hospital',
      phone: '+1 (555) 987-6543',
      email: 'maternity@cityhospital.org',
      address: '456 Hospital Drive, Downtown',
      isFavorite: false,
    ),
    Contact(
      name: 'Emma White',
      role: 'Midwife',
      phone: '+1 (555) 234-5678',
      email: 'emma.white@example.com',
      address: '789 Birthing Center Rd, Westside',
      isFavorite: true,
    ),
    Contact(
      name: 'Maternal Health Helpline',
      role: 'Support',
      phone: '+1 (800) 555-1234',
      email: 'support@maternalhealth.org',
      address: 'Available 24/7',
      isFavorite: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resources'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.secondaryTextColor,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.article_outlined),
              text: 'Articles',
            ),
            Tab(
              icon: Icon(Icons.contact_phone_outlined),
              text: 'Contacts',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Articles Tab
          _buildArticlesTab(),
          
          // Contacts Tab
          _buildContactsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Emergency call feature will be implemented soon'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.emergency, color: Colors.white),
      ),
    );
  }

  Widget _buildArticlesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search,
                  color: AppTheme.secondaryTextColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search resources...',
                      hintStyle: TextStyle(
                        color: AppTheme.secondaryTextColor.withOpacity(0.6),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Categories
          Text(
            'Categories',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryCard('Nutrition', Icons.restaurant, const Color(0xFFFF8FAB)),
                _buildCategoryCard('Fitness', Icons.fitness_center, const Color(0xFF8CD3A9)),
                _buildCategoryCard('Medical', Icons.medical_services, const Color(0xFF7AC9E8)),
                _buildCategoryCard('Wellness', Icons.spa, const Color(0xFFFFD166)),
                _buildCategoryCard('Community', Icons.people, const Color(0xFFB39DDB)),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Featured Articles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Articles',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'See All',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _articles.length,
            itemBuilder: (context, index) {
              return _buildArticleCard(_articles[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, Color color) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildArticleCard(HealthResource article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // View article
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article image with category overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    // In a real app, use Image.asset or Image.network here
                    child: Center(
                      child: Icon(
                        _getCategoryIcon(article.category),
                        size: 60,
                        color: AppTheme.primaryColor.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      article.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: InkWell(
                    onTap: () {
                      // Toggle save
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        article.isSaved
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: article.isSaved
                            ? AppTheme.primaryColor
                            : AppTheme.secondaryTextColor,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Article content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.source,
                        size: 14,
                        color: AppTheme.secondaryTextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        article.source,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppTheme.secondaryTextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(article.publishDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'nutrition':
        return Icons.restaurant;
      case 'fitness':
        return Icons.fitness_center;
      case 'medical':
        return Icons.medical_services;
      case 'wellness':
        return Icons.spa;
      case 'community':
        return Icons.people;
      default:
        return Icons.article;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildContactsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Emergency contacts section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.red.shade400,
                Colors.red.shade300,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.emergency,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Emergency Contacts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'For medical emergencies, please call:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildEmergencyButton(
                      '911',
                      Icons.phone,
                      Colors.red.shade600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildEmergencyButton(
                      'Local Hospital',
                      Icons.local_hospital,
                      Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Healthcare providers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Healthcare Team',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
              onPressed: () {
                // Add new contact
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Contact List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _contacts.length,
          itemBuilder: (context, index) {
            return _buildContactCard(_contacts[index]);
          },
        ),
      ],
    );
  }

  Widget _buildEmergencyButton(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Make emergency call
        },
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(Contact contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // View contact details
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Avatar or icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        _getContactIcon(contact.role),
                        color: AppTheme.secondaryColor,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Contact info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          contact.role,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Favorite icon
                  IconButton(
                    icon: Icon(
                      contact.isFavorite
                          ? Icons.star
                          : Icons.star_border,
                      color: contact.isFavorite
                          ? const Color(0xFFFFD700)
                          : AppTheme.secondaryTextColor,
                    ),
                    onPressed: () {
                      // Toggle favorite
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Contact actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildContactAction(
                    'Call',
                    Icons.phone,
                    AppTheme.primaryColor,
                  ),
                  _buildContactAction(
                    'Message',
                    Icons.message,
                    AppTheme.secondaryColor,
                  ),
                  _buildContactAction(
                    'Email',
                    Icons.email,
                    Colors.orange,
                  ),
                  _buildContactAction(
                    'Locate',
                    Icons.location_on,
                    Colors.blue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getContactIcon(String role) {
    switch (role.toLowerCase()) {
      case 'ob/gyn':
      case 'doctor':
        return Icons.medical_services;
      case 'midwife':
        return Icons.child_friendly;
      case 'hospital':
        return Icons.local_hospital;
      case 'support':
        return Icons.support_agent;
      default:
        return Icons.person;
    }
  }

  Widget _buildContactAction(String label, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        // Perform action
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class HealthResource {
  final String title;
  final String category;
  final String imageUrl;
  final String source;
  bool isSaved;
  final DateTime publishDate;

  HealthResource({
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.source,
    required this.isSaved,
    required this.publishDate,
  });
}

class Contact {
  final String name;
  final String role;
  final String phone;
  final String email;
  final String address;
  bool isFavorite;

  Contact({
    required this.name,
    required this.role,
    required this.phone,
    required this.email,
    required this.address,
    required this.isFavorite,
  });
} 