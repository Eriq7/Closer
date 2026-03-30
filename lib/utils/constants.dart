// constants.dart
// App-wide constants: label definitions, scoring thresholds, and window logic parameters.

enum RelationshipLabel {
  active,
  responsive,
  obligatory,
  cutOff;

  String get displayName {
    switch (this) {
      case active:
        return 'Active';
      case responsive:
        return 'Responsive';
      case obligatory:
        return 'Obligatory';
      case cutOff:
        return 'Cut-off';
    }
  }

  String get description {
    switch (this) {
      case active:
        return 'Core friends — proactively maintain';
      case responsive:
        return 'Respond when they reach out, don\'t initiate';
      case obligatory:
        return 'Maintain for practical reasons, want distance';
      case cutOff:
        return 'No longer in contact';
    }
  }

  String get dbValue {
    switch (this) {
      case active:
        return 'active';
      case responsive:
        return 'responsive';
      case obligatory:
        return 'obligatory';
      case cutOff:
        return 'cut_off';
    }
  }

  static RelationshipLabel fromDb(String value) {
    switch (value) {
      case 'active':
        return active;
      case 'responsive':
        return responsive;
      case 'obligatory':
        return obligatory;
      case 'cut_off':
        return cutOff;
      default:
        return responsive;
    }
  }
}

// Score descriptions shown to users when picking a score.
const Map<int, String> scoreDescriptions = {
  3: 'Came through in a crisis',
  2: 'Meaningful help (referral, serious support, solved a real problem)',
  1: 'Positive everyday interaction',
  0: 'Neutral — no real feeling',
  -1: 'Minor drain (cold water, passive-aggressive)',
  -2: 'Clear harm (public put-down, ignored when needed, talked behind your back)',
  -3: 'Crossed a line (verbal abuse, violence, serious betrayal)',
};

// Rolling window: if avg days between interactions <= this, use 5-score window; else use 3.
const int highFrequencyThresholdDays = 21;
const int highFrequencyWindowSize = 5;
const int lowFrequencyWindowSize = 3;

// Window total thresholds that trigger label change prompts.
const int windowNegativeTrigger = -4; // -4 or lower triggers downgrade prompt
const int windowPositiveUpgrade = 2;  // Responsive reaching +2 can upgrade to Active

// How long without an Active-friend interaction before sending a reminder.
const int activeReminderDays = 21;

// How many days between Obligatory re-evaluation reminders.
const int obligatoryReEvalDays = 60;
