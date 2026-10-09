import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaccine_aapp/services/child_service.dart';

void main() {
  group('ChildService', () {
    test(
      'fetchChildrenForParent returns only children for the exact parent uid',
      () async {
        final firestore = FakeFirebaseFirestore();
        final service = ChildService(firestore: firestore);

        await firestore.collection('children').add({
          'parentId': 'parent_001',
          'childName': 'Salem',
          'birthDate': '2024-03-04',
          'gender': 'male',
          'approved': true,
          'createdAt': DateTime(2026, 4, 23),
        });
        await firestore.collection('children').add({
          'parentId': 'other_parent',
          'childName': 'Maha',
          'birthDate': '2023-01-10',
          'gender': 'female',
          'approved': false,
          'createdAt': DateTime(2026, 4, 22),
        });

        final result = await service.fetchChildrenForParent('parent_001');

        expect(result, hasLength(1));
        expect(result.first.childName, 'Salem');
        expect(result.first.parentId, 'parent_001');
      },
    );

    test('trimAllParentIds cleans old whitespace-polluted ids', () async {
      final firestore = FakeFirebaseFirestore();
      final service = ChildService(firestore: firestore);

      await firestore.collection('children').add({
        'parentId': ' parent_001 ',
        'childName': 'Rawan',
        'birthDate': '2024-05-01',
        'gender': 'female',
        'approved': false,
        'createdAt': DateTime(2026, 4, 23),
      });

      final before = await service.fetchChildrenForParent('parent_001');
      expect(before, isEmpty);

      final updated = await service.trimAllParentIds();
      final after = await service.fetchChildrenForParent('parent_001');

      expect(updated, 1);
      expect(after, hasLength(1));
      expect(after.first.childName, 'Rawan');
      expect(after.first.parentId, 'parent_001');
    });
  });
}
