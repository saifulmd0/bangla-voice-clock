/// Bangla words used in time announcements.
///
/// Each word maps to a clip key in a voice pack; see [ClipKeys].
library;

abstract final class ClipKeys {
  static const starter = 'starter';
  static String hour(int h12) => 'hour.$h12';
  static String zone(DayZone zone) => 'zone.${zone.name}';
  static const sowa = 'qtr.sowa';
  static const sare = 'qtr.sare';
  static const poune = 'qtr.poune';
  static const der = 'half.der';
  static const arai = 'half.arai';
  static const beje = 'exact.beje';
  static const minute = 'exact.minute';
  static String number(int n) => 'num.$n';
}

/// Parts of the day, which a Bangla time announcement names before the hour.
enum DayZone {
  bhor('ভোর'),
  sokal('সকাল'),
  dupur('দুপুর'),
  bikal('বিকাল'),
  sondha('সন্ধ্যা'),
  raat('রাত');

  const DayZone(this.word);

  final String word;
}

const starterWord = 'এখন সময়';
const sowaWord = 'সোয়া';
const sareWord = 'সাড়ে';
const pouneWord = 'পৌনে';
const derWord = 'দেড়টা';
const araiWord = 'আড়াইটা';
const bejeWord = 'বেজে';
const minuteWord = 'মিনিট';

/// "একটা" … "বারোটা", indexed by 12-hour value (index 0 unused).
const hourWords = [
  '',
  'একটা',
  'দুইটা',
  'তিনটা',
  'চারটা',
  'পাঁচটা',
  'ছয়টা',
  'সাতটা',
  'আটটা',
  'নয়টা',
  'দশটা',
  'এগারোটা',
  'বারোটা',
];

/// Number words 1–59, indexed by value (index 0 unused).
///
/// Every Bangla number up to 99 is its own word rather than a regular
/// tens-plus-units pattern, so each needs its own entry and its own clip.
// dart format off
const numberWords = [
  '',
  'এক', 'দুই', 'তিন', 'চার', 'পাঁচ', 'ছয়', 'সাত', 'আট', 'নয়', 'দশ',
  'এগারো', 'বারো', 'তেরো', 'চৌদ্দ', 'পনেরো', 'ষোলো', 'সতেরো', 'আঠারো', 'উনিশ', 'বিশ',
  'একুশ', 'বাইশ', 'তেইশ', 'চব্বিশ', 'পঁচিশ', 'ছাব্বিশ', 'সাতাশ', 'আটাশ', 'ঊনত্রিশ', 'ত্রিশ',
  'একত্রিশ', 'বত্রিশ', 'তেত্রিশ', 'চৌত্রিশ', 'পঁয়ত্রিশ', 'ছত্রিশ', 'সাঁইত্রিশ', 'আটত্রিশ', 'ঊনচল্লিশ', 'চল্লিশ',
  'একচল্লিশ', 'বিয়াল্লিশ', 'তেতাল্লিশ', 'চুয়াল্লিশ', 'পঁয়তাল্লিশ', 'ছেচল্লিশ', 'সাতচল্লিশ', 'আটচল্লিশ', 'ঊনপঞ্চাশ', 'পঞ্চাশ',
  'একান্ন', 'বাহান্ন', 'তিপ্পান্ন', 'চুয়ান্ন', 'পঞ্চান্ন', 'ছাপ্পান্ন', 'সাতান্ন', 'আটান্ন', 'ঊনষাট',
];
// dart format on
