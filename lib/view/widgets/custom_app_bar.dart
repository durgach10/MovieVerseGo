import 'package:flutter/material.dart';
import 'package:movieversego/data/models/city.dart';

class CustomAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.selectedCity,
    this.onCityTap,
    this.onSearch,
    this.onProfile,
    this.onMenu,
  });

  final City? selectedCity;
  final VoidCallback? onCityTap;
  final VoidCallback? onSearch;
  final VoidCallback? onProfile;
  final VoidCallback? onMenu;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      title: GestureDetector(
        onTap: onCityTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on,
              color: Colors.yellow,
              size: 20,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                selectedCity?.name ?? "Select City",
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.yellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              color: Colors.yellow,
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.search,
            color: Colors.white,
          ),
          onPressed: onSearch,
        ),
        IconButton(
          icon: const Icon(
            Icons.person,
            color: Colors.white,
          ),
          onPressed: onProfile,
        ),
        IconButton(
          icon: const Icon(
            Icons.menu,
            color: Colors.white,
          ),
          onPressed: onMenu,
        ),
      ],
    );
  }
}