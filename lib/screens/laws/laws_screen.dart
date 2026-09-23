import 'package:flutter/material.dart';

class LawsScreen extends StatefulWidget {
  const LawsScreen({super.key});

  @override
  State<LawsScreen> createState() => _LawsScreenState();
}

class _LawsScreenState extends State<LawsScreen> {
  static const Color primaryColor = Color(0xFFE66C75);
  static const Color darkBackground = Color(0xFF111318);
  static const Color cardBackground = Color(0xFF1A1D24);

  int _selectedCategoryIndex = 0;
  String _selectedJurisdiction = 'All Jurisdictions';

  final List<String> _categories = const [
    'All Statutes',
    'Constitutional Law',
    'Criminal & Penal',
    'Commercial & Corporate',
    'Property & Land',
    'Electoral & Civic',
  ];

  final List<String> _jurisdictions = const [
    'All Jurisdictions',
    'Federal Laws (LFN)',
    'Lagos State',
    'FCT Abuja',
    'Rivers State',
    'Kano State',
  ];

  final List<LawModel> _lawsList = [
    LawModel(
      id: 'LFN-CON-1999',
      title: 'Constitution of the Federal Republic of Nigeria 1999',
      subTitle: 'As amended (1st - 5th Alteration Acts)',
      jurisdiction: 'Federal Laws (LFN)',
      category: 'Constitutional Law',
      enactmentYear: 1999,
      sectionsCount: 320,
      isDownloaded: true,
      isBookmarked: true,
      fileSizeMb: '4.2 MB',
    ),
    LawModel(
      id: 'LFN-ACT-2022-06',
      title: 'Electoral Act 2022',
      subTitle: 'Act No. 6 of 2022 • Regulates Conduct of Elections',
      jurisdiction: 'Federal Laws (LFN)',
      category: 'Electoral & Civic',
      enactmentYear: 2022,
      sectionsCount: 155,
      isDownloaded: true,
      isBookmarked: false,
      fileSizeMb: '2.8 MB',
    ),
     LawModel(
      id: 'LFN-CAM-2020',
      title: 'Companies and Allied Matters Act (CAMA) 2020',
      subTitle: 'Repealed CAMA 1990 • Corporate Structure & CAC Regulation',
      jurisdiction: 'Federal Laws (LFN)',
      category: 'Commercial & Corporate',
      enactmentYear: 2020,
      sectionsCount: 870,
      isDownloaded: false,
      isBookmarked: true,
      fileSizeMb: '8.5 MB',
    ),
     LawModel(
      id: 'LFN-ACJ-2015',
      title: 'Administration of Criminal Justice Act (ACJA) 2015',
      subTitle: 'Federal Criminal Procedure & Speedy Dispensation of Justice',
      jurisdiction: 'Federal Laws (LFN)',
      category: 'Criminal & Penal',
      enactmentYear: 2015,
      sectionsCount: 495,
      isDownloaded: false,
      isBookmarked: false,
      fileSizeMb: '5.1 MB',
    ),
     LawModel(
      id: 'LASG-TEN-2011',
      title: 'Lagos State Tenancy Law 2011',
      subTitle: 'Regulates Rights & Obligations of Landlords and Tenants',
      jurisdiction: 'Lagos State',
      category: 'Property & Land',
      enactmentYear: 2011,
      sectionsCount: 48,
      isDownloaded: true,
      isBookmarked: false,
      fileSizeMb: '1.2 MB',
    ),
  ];

  List<LawModel> get _filteredLaws {
    return _lawsList.where((law) {
      final matchesCategory = _selectedCategoryIndex == 0 ||
          law.category == _categories[_selectedCategoryIndex];
      final matchesJurisdiction = _selectedJurisdiction == 'All Jurisdictions' ||
          law.jurisdiction == _selectedJurisdiction;
      return matchesCategory && matchesJurisdiction;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Laws & Statutes',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              'Laws of the Federation & State Legislation',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_for_offline_outlined,
                color: primaryColor, size: 22),
            onPressed: () {
              // Action: Manage offline downloaded laws
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search statutes, Act numbers, or year...',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 14,
                    ),
                    icon: Icon(
                      Icons.search_rounded,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            // Jurisdiction Filter & Counter Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Jurisdiction Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: primaryColor.withOpacity(0.25)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedJurisdiction,
                        dropdownColor: cardBackground,
                        icon: const Icon(Icons.arrow_drop_down_rounded,
                            color: primaryColor),
                        style: const TextStyle(
                          color: primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedJurisdiction = val;
                            });
                          }
                        },
                        items: _jurisdictions.map((j) {
                          return DropdownMenuItem(
                            value: j,
                            child: Text(j),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // Results Count
                  Text(
                    '${_filteredLaws.length} Statutes Found',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Horizontal Category Chips
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedCategoryIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_categories[index]),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategoryIndex = index;
                        });
                      },
                      selectedColor: primaryColor,
                      backgroundColor: cardBackground,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.6),
                        fontSize: 12,
                        fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? primaryColor
                            : Colors.white.withOpacity(0.08),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      showCheckmark: false,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Laws & Statutes List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                itemCount: _filteredLaws.length,
                itemBuilder: (context, index) {
                  final law = _filteredLaws[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildLawTile(law),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLawTile(LawModel law) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Tags (Jurisdiction + Category)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      law.jurisdiction,
                      style: const TextStyle(
                        color: primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      law.category,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              // Bookmark Toggle
              IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                icon: Icon(
                  law.isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: law.isBookmarked
                      ? primaryColor
                      : Colors.white.withOpacity(0.3),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    law.isBookmarked = !law.isBookmarked;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Law Title
          Text(
            law.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 4),

          // Subtitle / Scope
          Text(
            law.subTitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 12,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 14),

          Divider(color: Colors.white.withOpacity(0.06), height: 1),

          const SizedBox(height: 12),

          // Bottom Meta Row & Download Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.menu_book_rounded,
                      color: Colors.white.withOpacity(0.4), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '${law.sectionsCount} Sections',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.calendar_today_rounded,
                      color: Colors.white.withOpacity(0.4), size: 13),
                  const SizedBox(width: 4),
                  Text(
                    '${law.enactmentYear}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              // Offline Download Action
              GestureDetector(
                onTap: () {
                  setState(() {
                    law.isDownloaded = !law.isDownloaded;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        law.isDownloaded
                            ? '${law.title} downloaded for offline access.'
                            : 'Removed from offline storage.',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: law.isDownloaded
                        ? Colors.purple.withOpacity(0.15)
                        : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: law.isDownloaded
                          ? Colors.purple.withOpacity(0.3)
                          : Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        law.isDownloaded
                            ? Icons.check_circle_rounded
                            : Icons.download_rounded,
                        color: law.isDownloaded
                            ? Colors.purple
                            : Colors.white.withOpacity(0.7),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        law.isDownloaded ? 'Offline' : law.fileSizeMb,
                        style: TextStyle(
                          color: law.isDownloaded
                              ? Colors.purple
                              : Colors.white.withOpacity(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LawModel {
  final String id;
  final String title;
  final String subTitle;
  final String jurisdiction;
  final String category;
  final int enactmentYear;
  final int sectionsCount;
  bool isDownloaded;
  bool isBookmarked;
  final String fileSizeMb;

  LawModel({
    required this.id,
    required this.title,
    required this.subTitle,
    required this.jurisdiction,
    required this.category,
    required this.enactmentYear,
    required this.sectionsCount,
    required this.isDownloaded,
    required this.isBookmarked,
    required this.fileSizeMb,
  });
}