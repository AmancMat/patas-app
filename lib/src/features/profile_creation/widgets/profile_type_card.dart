import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';

/// Card moderno para seleção de tipo de perfil
/// Suporta tanto ícones quanto imagens
class ProfileTypeCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? imagePath;
  final Color? iconColor;
  final VoidCallback onTap;
  final bool
      isLarge; // Para diferenciar pets (grandes) de organizações (médios)

  const ProfileTypeCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.imagePath,
    this.iconColor,
    required this.onTap,
    this.isLarge = false,
  }) : assert(icon != null || imagePath != null,
            'Deve fornecer icon ou imagePath');

  @override
  State<ProfileTypeCard> createState() => _ProfileTypeCardState();
}

class _ProfileTypeCardState extends State<ProfileTypeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: widget.isLarge ? 160.0 : 120.0,
          width: widget.isLarge ? 160.0 : double.infinity,
          decoration: BoxDecoration(
            color: _isPressed
                ? (isDark ? Colors.grey[800] : Colors.grey[100])
                : (isDark ? AppColors.darkBG : Colors.white),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: _isPressed
                  ? AppColors.patasColor
                  : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
              width: _isPressed ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _isPressed
                    ? AppColors.patasColor.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                blurRadius: _isPressed ? 12.0 : 8.0,
                offset: Offset(0, _isPressed ? 4.0 : 2.0),
              ),
            ],
          ),
          child: widget.isLarge
              ? _buildLargeContent(isDark)
              : _buildCompactContent(isDark),
        ),
      ),
    );
  }

  // Layout para cards grandes (Pets)
  Widget _buildLargeContent(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.imagePath != null)
          Image.asset(
            widget.imagePath!,
            height: 80.0,
            width: 80.0,
            fit: BoxFit.contain,
          )
        else if (widget.icon != null)
          Icon(
            widget.icon,
            size: 64.0,
            color: widget.iconColor ?? AppColors.patasColor,
          ),
        SizedBox(height: 12.0),
        Text(
          widget.title,
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.darkBG,
            fontFamily: 'Fredoka',
          ),
        ),
      ],
    );
  }

  // Layout para cards compactos (ONGs/Empresas)
  Widget _buildCompactContent(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        children: [
          // Ícone
          Container(
            width: 56.0,
            height: 56.0,
            decoration: BoxDecoration(
              color: (widget.iconColor ?? AppColors.patasColor)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(
              widget.icon,
              size: 32.0,
              color: widget.iconColor ?? AppColors.patasColor,
            ),
          ),
          SizedBox(width: 16.0),
          // Textos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.darkBG,
                    fontFamily: 'Fredoka',
                  ),
                ),
                if (widget.subtitle != null) ...[
                  SizedBox(height: 4.0),
                  Text(
                    widget.subtitle!,
                    style: TextStyle(
                      fontSize: 13.0,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Seta
          Icon(
            Icons.chevron_right,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
            size: 24.0,
          ),
        ],
      ),
    );
  }
}
