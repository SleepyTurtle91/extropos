import 'package:extropos/models/loyalty_member.dart';
import 'package:extropos/models/loyalty_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Loyalty Member Tests
  group('LoyaltyMember Tests', () {
    test('creates member with correct properties', () {
      final member = LoyaltyMember(
        id: 'mem_1',
        name: 'John Doe',
        phone: '0123456789',
        email: 'john@email.com',
        joinDate: DateTime(2025, 1, 1),
        currentTier: 'Silver',
        totalPoints: 500,
        redeemedPoints: 100,
        lastPurchaseDate: DateTime(2026, 1, 20),
        totalSpent: 1500.0,
      );

      expect(member.id, 'mem_1');
      expect(member.name, 'John Doe');
      expect(member.phone, '0123456789');
      expect(member.currentTier, 'Silver');
      expect(member.totalPoints, 500);
    });

    test('calculates available points correctly', () {
      final member = LoyaltyMember(
        id: 'mem_1',
        name: 'Jane Doe',
        phone: '0198765432',
        email: 'jane@email.com',
        joinDate: DateTime.now(),
        currentTier: 'Gold',
        totalPoints: 1000,
        redeemedPoints: 300,
        lastPurchaseDate: DateTime.now(),
        totalSpent: 3000.0,
      );

      expect(member.availablePoints, 700);
    });

    test('isActive returns true for recent purchase', () {
      final member = LoyaltyMember(
        id: 'mem_2',
        name: 'Alice Smith',
        phone: '0111111111',
        email: 'alice@email.com',
        joinDate: DateTime(2024, 1, 1),
        currentTier: 'Silver',
        totalPoints: 250,
        redeemedPoints: 50,
        lastPurchaseDate: DateTime.now().subtract(Duration(days: 30)),
        totalSpent: 800.0,
      );

      expect(member.isActive, true);
    });

    test('isActive returns false for old purchase', () {
      final member = LoyaltyMember(
        id: 'mem_3',
        name: 'Bob Johnson',
        phone: '0122222222',
        email: 'bob@email.com',
        joinDate: DateTime(2023, 1, 1),
        currentTier: 'Bronze',
        totalPoints: 100,
        redeemedPoints: 0,
        lastPurchaseDate: DateTime.now().subtract(Duration(days: 200)),
        totalSpent: 300.0,
      );

      expect(member.isActive, false);
    });

    test('gets correct tier level', () {
      final gold = LoyaltyMember(
        id: 'mem_4',
        name: 'Test Gold',
        phone: '0133333333',
        email: 'gold@email.com',
        joinDate: DateTime.now(),
        currentTier: 'Gold',
        totalPoints: 1000,
        redeemedPoints: 100,
        lastPurchaseDate: DateTime.now(),
        totalSpent: 2500.0,
      );

      expect(gold.tierLevel, 3);
    });

    test('copyWith updates only specified fields', () {
      final original = LoyaltyMember(
        id: 'mem_5',
        name: 'Original Name',
        phone: '0144444444',
        email: 'original@email.com',
        joinDate: DateTime(2025, 1, 1),
        currentTier: 'Silver',
        totalPoints: 500,
        redeemedPoints: 100,
        lastPurchaseDate: DateTime.now(),
        totalSpent: 1500.0,
      );

      final updated = original.copyWith(
        name: 'Updated Name',
        totalPoints: 750,
      );

      expect(updated.name, 'Updated Name');
      expect(updated.totalPoints, 750);
      expect(updated.phone, original.phone);
      expect(updated.email, original.email);
    });

    test('toMap and fromMap roundtrip', () {
      final original = LoyaltyMember(
        id: 'mem_6',
        name: 'Roundtrip Test',
        phone: '0155555555',
        email: 'roundtrip@email.com',
        joinDate: DateTime(2025, 6, 15),
        currentTier: 'Platinum',
        totalPoints: 2000,
        redeemedPoints: 300,
        lastPurchaseDate: DateTime(2026, 1, 20),
        totalSpent: 6000.0,
      );

      final map = original.toMap();
      final restored = LoyaltyMember.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.totalPoints, original.totalPoints);
    });

    test('JSON serialization roundtrip', () {
      final original = LoyaltyMember(
        id: 'mem_7',
        name: 'JSON Test',
        phone: '0166666666',
        email: 'json@email.com',
        joinDate: DateTime(2025, 3, 10),
        currentTier: 'Gold',
        totalPoints: 1500,
        redeemedPoints: 200,
        lastPurchaseDate: DateTime(2026, 1, 19),
        totalSpent: 4500.0,
      );

      final json = original.toJson();
      final restored = LoyaltyMember.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.totalPoints, original.totalPoints);
    });
  });

  // Loyalty Transaction Tests
  group('LoyaltyTransaction Tests', () {
    test('creates transaction with correct properties', () {
      final tx = LoyaltyTransaction(
        id: 'tx_1',
        memberId: 'mem_1',
        transactionType: 'Purchase',
        amount: 150.0,
        pointsEarned: 150,
        pointsRedeemed: 0,
        transactionDate: DateTime(2026, 1, 20),
      );

      expect(tx.id, 'tx_1');
      expect(tx.transactionType, 'Purchase');
      expect(tx.pointsEarned, 150);
      expect(tx.isPurchase, true);
    });

    test('calculates net points change', () {
      final tx = LoyaltyTransaction(
        id: 'tx_2',
        memberId: 'mem_2',
        transactionType: 'Adjustment',
        amount: 0,
        pointsEarned: 200,
        pointsRedeemed: 50,
        transactionDate: DateTime.now(),
      );

      expect(tx.netPointsChange, 150);
    });

    test('detects purchase transactions', () {
      final purchase = LoyaltyTransaction(
        id: 'tx_3',
        memberId: 'mem_3',
        transactionType: 'Purchase',
        amount: 100.0,
        pointsEarned: 100,
        pointsRedeemed: 0,
        transactionDate: DateTime.now(),
      );

      expect(purchase.isPurchase, true);
    });

    test('detects reward redemption', () {
      final reward = LoyaltyTransaction(
        id: 'tx_4',
        memberId: 'mem_4',
        transactionType: 'Reward',
        amount: 0,
        pointsEarned: 0,
        pointsRedeemed: 100,
        transactionDate: DateTime.now(),
      );

      expect(reward.isRedemption, true);
    });

    test('copyWith updates transaction fields', () {
      final original = LoyaltyTransaction(
        id: 'tx_5',
        memberId: 'mem_5',
        transactionType: 'Purchase',
        amount: 200.0,
        pointsEarned: 200,
        pointsRedeemed: 0,
        transactionDate: DateTime.now(),
        notes: 'Original note',
      );

      final updated = original.copyWith(
        amount: 250.0,
        notes: 'Updated note',
      );

      expect(updated.amount, 250.0);
      expect(updated.notes, 'Updated note');
      expect(updated.pointsEarned, original.pointsEarned);
    });

    test('toMap and fromMap roundtrip', () {
      final original = LoyaltyTransaction(
        id: 'tx_6',
        memberId: 'mem_6',
        transactionType: 'Purchase',
        amount: 175.50,
        pointsEarned: 175,
        pointsRedeemed: 0,
        transactionDate: DateTime(2026, 1, 15),
        notes: 'Regular purchase',
      );

      final map = original.toMap();
      final restored = LoyaltyTransaction.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.memberId, original.memberId);
      expect(restored.amount, original.amount);
    });

    test('JSON serialization roundtrip', () {
      final original = LoyaltyTransaction(
        id: 'tx_7',
        memberId: 'mem_7',
        transactionType: 'Reward',
        amount: 0,
        pointsEarned: 0,
        pointsRedeemed: 500,
        transactionDate: DateTime(2026, 1, 18),
        notes: 'Reward redemption',
      );

      final json = original.toJson();
      final restored = LoyaltyTransaction.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.pointsRedeemed, original.pointsRedeemed);
      expect(restored.notes, original.notes);
    });
  });

  // Integration Tests
  group('Tier Calculation Tests', () {
    test('calculates Platinum tier correctly', () {
      final member = LoyaltyMember(
        id: 'mem_plat',
        name: 'Platinum Member',
        phone: '0177777777',
        email: 'platinum@email.com',
        joinDate: DateTime(2024, 1, 1),
        currentTier: 'Platinum',
        totalPoints: 5000,
        redeemedPoints: 1000,
        lastPurchaseDate: DateTime.now(),
        totalSpent: 6000.0,
      );

      expect(member.tierLevel, 4);
      expect(member.availablePoints, 4000);
    });

    test('calculates Gold tier correctly', () {
      final member = LoyaltyMember(
        id: 'mem_gold',
        name: 'Gold Member',
        phone: '0188888888',
        email: 'gold@email.com',
        joinDate: DateTime(2024, 6, 1),
        currentTier: 'Gold',
        totalPoints: 2000,
        redeemedPoints: 400,
        lastPurchaseDate: DateTime.now(),
        totalSpent: 2500.0,
      );

      expect(member.tierLevel, 3);
      expect(member.availablePoints, 1600);
    });

    test('handles zero points correctly', () {
      final member = LoyaltyMember(
        id: 'mem_zero',
        name: 'New Member',
        phone: '0199999999',
        email: 'new@email.com',
        joinDate: DateTime.now(),
        currentTier: 'Bronze',
        totalPoints: 0,
        redeemedPoints: 0,
        lastPurchaseDate: DateTime.now(),
        totalSpent: 0.0,
      );

      expect(member.availablePoints, 0);
      expect(member.totalSpent, 0.0);
    });
  });

  // Edge Case Tests
  group('Edge Case Tests', () {
    test('handles large point amounts', () {
      final member = LoyaltyMember(
        id: 'mem_large',
        name: 'VIP Member',
        phone: '0101010101',
        email: 'vip@email.com',
        joinDate: DateTime(2020, 1, 1),
        currentTier: 'Platinum',
        totalPoints: 1000000,
        redeemedPoints: 250000,
        lastPurchaseDate: DateTime.now(),
        totalSpent: 50000.0,
      );

      expect(member.availablePoints, 750000);
      expect(member.isActive, true);
    });

    test('handles decimal spending amounts', () {
      final member = LoyaltyMember(
        id: 'mem_decimal',
        name: 'Decimal Spender',
        phone: '0102020202',
        email: 'decimal@email.com',
        joinDate: DateTime.now(),
        currentTier: 'Silver',
        totalPoints: 550,
        redeemedPoints: 125,
        lastPurchaseDate: DateTime.now(),
        totalSpent: 1234.56,
      );

      expect(member.totalSpent, 1234.56);
      expect(member.availablePoints, 425);
    });

    test('handles special characters in name', () {
      final member = LoyaltyMember(
        id: 'mem_special',
        name: "O'Brien-Smith",
        phone: '0103030303',
        email: 'obrien@email.com',
        joinDate: DateTime.now(),
        currentTier: 'Silver',
        totalPoints: 300,
        redeemedPoints: 50,
        lastPurchaseDate: DateTime.now(),
        totalSpent: 900.0,
      );

      expect(member.name, "O'Brien-Smith");
    });

    test('handles international phone numbers', () {
      final member = LoyaltyMember(
        id: 'mem_intl',
        name: 'International Member',
        phone: '+1-555-0123',
        email: 'intl@email.com',
        joinDate: DateTime.now(),
        currentTier: 'Gold',
        totalPoints: 1500,
        redeemedPoints: 200,
        lastPurchaseDate: DateTime.now(),
        totalSpent: 3500.0,
      );

      expect(member.phone, '+1-555-0123');
    });

    test('handles empty email', () {
      final member = LoyaltyMember(
        id: 'mem_noemail',
        name: 'No Email Member',
        phone: '0104040404',
        email: '',
        joinDate: DateTime.now(),
        currentTier: 'Bronze',
        totalPoints: 100,
        redeemedPoints: 0,
        lastPurchaseDate: DateTime.now(),
        totalSpent: 250.0,
      );

      expect(member.email, '');
      expect(member.availablePoints, 100);
    });

    test('handles transaction with empty notes', () {
      final tx = LoyaltyTransaction(
        id: 'tx_empty',
        memberId: 'mem_8',
        transactionType: 'Purchase',
        amount: 100.0,
        pointsEarned: 100,
        pointsRedeemed: 0,
        transactionDate: DateTime.now(),
        notes: '',
      );

      expect(tx.notes, '');
      expect(tx.isPurchase, true);
    });

    test('handles multi-line transaction notes', () {
      final notes = 'Purchase made on January 20\nIn-store transaction\nPayment: Card';

      final tx = LoyaltyTransaction(
        id: 'tx_multiline',
        memberId: 'mem_9',
        transactionType: 'Purchase',
        amount: 200.0,
        pointsEarned: 200,
        pointsRedeemed: 0,
        transactionDate: DateTime.now(),
        notes: notes,
      );

      expect(tx.notes, notes);
      expect(tx.notes.contains('\n'), true);
    });
  });

  // Status Tests
  group('Member Status Tests', () {
    test('identifies new members correctly', () {
      final newMember = LoyaltyMember(
        id: 'mem_new',
        name: 'Brand New Member',
        phone: '0105050505',
        email: 'new@email.com',
        joinDate: DateTime.now(),
        currentTier: 'Bronze',
        totalPoints: 0,
        redeemedPoints: 0,
        lastPurchaseDate: DateTime.now(),
        totalSpent: 0.0,
      );

      expect(newMember.currentTier, 'Bronze');
      expect(newMember.totalPoints, 0);
    });

    test('identifies loyal customers', () {
      final loyalMember = LoyaltyMember(
        id: 'mem_loyal',
        name: 'Loyal Customer',
        phone: '0106060606',
        email: 'loyal@email.com',
        joinDate: DateTime(2020, 1, 1),
        currentTier: 'Platinum',
        totalPoints: 10000,
        redeemedPoints: 2000,
        lastPurchaseDate: DateTime.now(),
        totalSpent: 25000.0,
      );

      expect(loyalMember.isActive, true);
      expect(loyalMember.tierLevel, 4);
      expect(loyalMember.totalSpent, 25000.0);
    });
  });
}
