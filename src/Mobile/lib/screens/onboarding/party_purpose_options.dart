import 'package:flutter/material.dart';

class PartyPurposeOption {
  const PartyPurposeOption({
    required this.purposeType,
    required this.label,
    required this.icon,
  });

  final int purposeType;
  final String label;
  final IconData icon;
}

const List<PartyPurposeOption> kPartyPurposeOptions = [
  PartyPurposeOption(
    purposeType: 1,
    label: 'Sosyalleşme',
    icon: Icons.celebration_rounded,
  ),
  PartyPurposeOption(
    purposeType: 2,
    label: 'Flört',
    icon: Icons.favorite_rounded,
  ),
  PartyPurposeOption(
    purposeType: 3,
    label: 'Ağ kurma',
    icon: Icons.hub_rounded,
  ),
  PartyPurposeOption(
    purposeType: 4,
    label: 'Arkadaş edinme',
    icon: Icons.group_add_rounded,
  ),
  PartyPurposeOption(
    purposeType: 5,
    label: 'Keşfetme',
    icon: Icons.explore_rounded,
  ),
];
