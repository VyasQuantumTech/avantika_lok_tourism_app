class VerificationChallenge {
  const VerificationChallenge(
      {required this.id,
      required this.channel,
      required this.purpose,
      required this.destination,
      required this.expiresAt,
      required this.resendAt});
  final String id, channel, purpose, destination;
  final DateTime expiresAt, resendAt;
  Map<String, dynamic> toJson() => {
        'challengeId': id,
        'channel': channel,
        'purpose': purpose,
        'maskedDestination': destination,
        'expiresAt': expiresAt.toIso8601String(),
        'resendAt': resendAt.toIso8601String()
      };
  factory VerificationChallenge.fromJson(Map<String, dynamic> value) =>
      VerificationChallenge(
        id: value['challengeId'] as String,
        channel: value['channel'] as String,
        purpose: value['purpose'] as String,
        destination: value['maskedDestination'] as String,
        expiresAt: DateTime.parse(value['expiresAt'] as String),
        resendAt: DateTime.parse(value['resendAt'] as String),
      );
}
