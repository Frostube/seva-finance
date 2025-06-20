import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/onboarding_service.dart';
import '../services/auth_service.dart';

class OnboardingDebugScreen extends StatefulWidget {
  const OnboardingDebugScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingDebugScreen> createState() => _OnboardingDebugScreenState();
}

class _OnboardingDebugScreenState extends State<OnboardingDebugScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Onboarding Debug',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
      ),
      body: Consumer2<OnboardingService, AuthService>(
        builder: (context, onboardingService, authService, child) {
          final userOnboarding = onboardingService.userOnboarding;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Onboarding Status',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B4332),
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatusCard(
                    'Completed',
                    userOnboarding?.onboardingCompleted.toString() ??
                        'Unknown'),
                const SizedBox(height: 8),
                _buildStatusCard('Current Step',
                    userOnboarding?.currentStep.toString() ?? 'Unknown'),
                const SizedBox(height: 8),
                _buildStatusCard('Started At',
                    userOnboarding?.onboardingStartedAt?.toString() ?? 'Never'),
                const SizedBox(height: 8),
                _buildStatusCard(
                    'Completed At',
                    userOnboarding?.onboardingCompletedAt?.toString() ??
                        'Never'),
                const SizedBox(height: 8),
                _buildStatusCard('Completed Steps',
                    userOnboarding?.completedSteps.join(', ') ?? 'None'),
                const SizedBox(height: 8),

                // New user detection status
                FutureBuilder<bool>(
                  future: onboardingService.isNewUser(),
                  builder: (context, snapshot) {
                    return _buildStatusCard(
                        'Is New User',
                        snapshot.hasData
                            ? snapshot.data.toString()
                            : 'Loading...');
                  },
                ),
                const SizedBox(height: 8),
                _buildStatusCard('Should Show Onboarding',
                    onboardingService.shouldShowOnboarding.toString()),
                const SizedBox(height: 8),

                // Account creation date
                if (authService.user?.metadata.creationTime != null) ...[
                  _buildStatusCard('Account Created',
                      authService.user!.metadata.creationTime.toString()),
                  const SizedBox(height: 8),
                  _buildStatusCard(
                      'Days Since Creation',
                      DateTime.now()
                          .difference(authService.user!.metadata.creationTime!)
                          .inDays
                          .toString()),
                  const SizedBox(height: 8),
                ],
                
                const SizedBox(height: 32),
                Text(
                  'Actions',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B4332),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onboardingService.isLoading
                        ? null
                        : () async {
                      await onboardingService.resetOnboarding();
                            // Trigger a rebuild to show updated status
                            setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                                content: Text(
                                    'Onboarding reset! Go back to dashboard to see the tour.'),
                          backgroundColor: Color(0xFF1B4332),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4332),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      onboardingService.isLoading
                          ? 'Loading...'
                          : 'Reset Onboarding',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onboardingService.isLoading
                        ? null
                        : () async {
                      await onboardingService.completeOnboarding();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                                content:
                                    Text('Onboarding marked as completed!'),
                          backgroundColor: Color(0xFF40916C),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1B4332)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Mark as Completed',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1B4332),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onboardingService.isLoading
                        ? null
                        : () async {
                            await onboardingService.markAsExistingUser();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'User marked as existing - onboarding will not show'),
                                backgroundColor: Color(0xFF40916C),
                              ),
                            );
                          },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF40916C)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Mark as Existing User',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF40916C),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Debug Instructions',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Reset onboarding to trigger the tour again\n2. Navigate back to the main dashboard\n3. The tour should start automatically\n4. Test all steps and navigation',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1B4332),
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
} 
