import 'package:flutter/material.dart';
import 'book_delivery_screen.dart';

class RequestServiceScreen extends StatelessWidget {
  const RequestServiceScreen({super.key});

  // ================= COLORS =================

  static const Color primaryColor = Color(0xFF03A9F4);
  static const Color gradientStart = Color(0xFF81D4FA);
  static const Color gradientEnd = Color(0xFF0288D1);

  static const Color backgroundColor = Color(0xFFF4F8FD);
  static const Color lightBlue = Color(0xFFE1F5FE);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),

                padding: const EdgeInsets.fromLTRB(18, 20, 18, 25),

                children: [
                  const Text(
                    "Choose a Service",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0D1B2A),
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ================= SERVICES =================

                  _buildServiceCard(
                    context,
                    title: "Pick Up",
                    subtitle: "Fast package delivery",
                    icon: Icons.local_shipping_rounded,
                    type: ServiceType.pickup,
                  ),

                  _buildServiceCard(
                    context,
                    title: "Pabili",
                    subtitle: "Personal shopping service",
                    icon: Icons.shopping_bag_rounded,
                    type: ServiceType.pabili,
                  ),

                  _buildServiceCard(
                    context,
                    title: "Food Delivery",
                    subtitle: "Restaurant food delivery",
                    icon: Icons.fastfood_rounded,
                    type: ServiceType.food,
                  ),

                  _buildServiceCard(
                    context,
                    title: "Bills Payment",
                    subtitle: "Easy utility bill payment",
                    icon: Icons.receipt_long_rounded,
                    type: ServiceType.bills,
                  ),

                  const SizedBox(height: 22),

                  // ================= INFO =================

                  _buildInfoContainer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),

      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradientStart,
            gradientEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),

      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,

            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),

            child: IconButton(
              onPressed: () => Navigator.pop(context),

              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Text(
              "Request Service",
              overflow: TextOverflow.ellipsis,

              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= SERVICE CARD =================

  Widget _buildServiceCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required ServiceType type,
      }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookDeliveryScreen(
              initialType: type,
            ),
          ),
        );
      },

      child: Container(
        height: 102,

        margin: const EdgeInsets.only(bottom: 14),

        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF81D4FA),
              Color(0xFF29B6F6),
              Color(0xFF0288D1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),

          borderRadius: BorderRadius.circular(24),

          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.18),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),

        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),

          child: Row(
            children: [
              // ================= ICON =================

              Container(
                height: 56,
                width: 56,

                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(18),
                ),

                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),

              const SizedBox(width: 15),

              // ================= TEXT =================

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,

                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // ================= ARROW =================

              Container(
                height: 36,
                width: 36,

                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= INFO CONTAINER =================

  Widget _buildInfoContainer() {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),

        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Column(
        children: [
          _buildInfoTile(
            Icons.verified_user_rounded,
            "Verified Riders",
            "Trusted and background checked riders.",
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),

          _buildInfoTile(
            Icons.timer_rounded,
            "Fast Delivery",
            "Quick delivery within your area.",
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),

          _buildInfoTile(
            Icons.support_agent_rounded,
            "24/7 Support",
            "Support team ready anytime.",
          ),
        ],
      ),
    );
  }

  // ================= INFO TILE =================

  Widget _buildInfoTile(
      IconData icon,
      String title,
      String subtitle,
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Container(
          padding: const EdgeInsets.all(10),

          decoration: BoxDecoration(
            color: lightBlue,
            borderRadius: BorderRadius.circular(14),
          ),

          child: Icon(
            icon,
            color: primaryColor,
            size: 24,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,

                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF0D1B2A),
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,

                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}