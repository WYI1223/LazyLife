import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/features/workspace/workspace_models.dart';
import 'package:lazynote_flutter/features/workspace/workspace_provider.dart';

void main() {
  test('WorkspaceLayoutState snapshots are defensively immutable', () {
    final paneOrder = <String>['pane.primary'];
    final paneFractions = <double>[1.0];
    final state = WorkspaceLayoutState(
      paneOrder: paneOrder,
      paneFractions: paneFractions,
      splitDirection: WorkspaceSplitDirection.horizontal,
      primaryPaneId: 'pane.primary',
    );

    paneOrder.add('pane.mutated');
    paneFractions[0] = 0.25;

    expect(state.paneOrder, ['pane.primary']);
    expect(state.paneFractions, [1.0]);
    expect(() => state.paneOrder.add('pane.extra'), throwsUnsupportedError);
    expect(() => state.paneFractions.add(0.5), throwsUnsupportedError);

    final copied = state.copyWith();
    expect(copied.paneOrder, ['pane.primary']);
    expect(copied.paneFractions, [1.0]);
    expect(() => copied.paneOrder.add('pane.copy'), throwsUnsupportedError);
  });

  test('splitActivePane creates a second pane and focuses the new pane', () {
    final provider = WorkspaceProvider();
    addTearDown(provider.dispose);

    final result = provider.splitActivePane(
      direction: WorkspaceSplitDirection.horizontal,
      containerExtent: 1200,
    );

    expect(result, WorkspaceSplitResult.ok);
    expect(provider.layoutState.paneOrder.length, 2);
    expect(provider.layoutState.paneFractions, const [0.5, 0.5]);
    expect(
      provider.layoutState.splitDirection,
      WorkspaceSplitDirection.horizontal,
    );
    expect(provider.activePaneId, provider.layoutState.paneOrder.last);
  });

  test('splitActivePane blocks when min-size guard would be violated', () {
    final provider = WorkspaceProvider();
    addTearDown(provider.dispose);

    final result = provider.splitActivePane(
      direction: WorkspaceSplitDirection.horizontal,
      containerExtent: 360,
    );

    expect(result, WorkspaceSplitResult.minSizeBlocked);
    expect(provider.layoutState.paneOrder.length, 1);
  });

  test('splitActivePane keeps root direction locked after first split', () {
    final provider = WorkspaceProvider();
    addTearDown(provider.dispose);

    final first = provider.splitActivePane(
      direction: WorkspaceSplitDirection.horizontal,
      containerExtent: 1200,
    );
    expect(first, WorkspaceSplitResult.ok);

    final second = provider.splitActivePane(
      direction: WorkspaceSplitDirection.vertical,
      containerExtent: 900,
    );
    expect(second, WorkspaceSplitResult.directionLocked);
  });

  test('splitActivePane enforces max pane count', () {
    final provider = WorkspaceProvider();
    addTearDown(provider.dispose);

    String paneWithLargestFraction() {
      var maxIndex = 0;
      var maxFraction = provider.layoutState.paneFractions.first;
      for (
        var index = 1;
        index < provider.layoutState.paneFractions.length;
        index += 1
      ) {
        final candidate = provider.layoutState.paneFractions[index];
        if (candidate > maxFraction) {
          maxFraction = candidate;
          maxIndex = index;
        }
      }
      return provider.layoutState.paneOrder[maxIndex];
    }

    for (var attempt = 0; attempt < 3; attempt += 1) {
      provider.switchActivePane(paneWithLargestFraction());
      expect(
        provider.splitActivePane(
          direction: WorkspaceSplitDirection.horizontal,
          containerExtent: 1200,
        ),
        WorkspaceSplitResult.ok,
      );
    }
    expect(provider.layoutState.paneOrder.length, 4);

    final blocked = provider.splitActivePane(
      direction: WorkspaceSplitDirection.horizontal,
      containerExtent: 1200,
    );
    expect(blocked, WorkspaceSplitResult.maxPanesReached);
    expect(provider.layoutState.paneOrder.length, 4);
  });

  test('closeActivePane blocks when only one pane exists', () {
    final provider = WorkspaceProvider();
    addTearDown(provider.dispose);

    final result = provider.closeActivePane();

    expect(result, WorkspaceMergeResult.singlePaneBlocked);
    expect(provider.layoutState.paneOrder.length, 1);
  });

  test('closeActivePane merges active split pane into previous pane', () {
    final provider = WorkspaceProvider();
    addTearDown(provider.dispose);

    expect(
      provider.splitActivePane(
        direction: WorkspaceSplitDirection.horizontal,
        containerExtent: 1200,
      ),
      WorkspaceSplitResult.ok,
    );
    final primaryPane = provider.layoutState.primaryPaneId;

    final merged = provider.closeActivePane();

    expect(merged, WorkspaceMergeResult.ok);
    expect(provider.layoutState.paneOrder, [primaryPane]);
    expect(provider.layoutState.paneFractions, [1.0]);
    expect(provider.activePaneId, primaryPane);
  });

  test('closeActivePane uses next pane when closing first pane', () {
    final provider = WorkspaceProvider();
    addTearDown(provider.dispose);

    expect(
      provider.splitActivePane(
        direction: WorkspaceSplitDirection.horizontal,
        containerExtent: 1200,
      ),
      WorkspaceSplitResult.ok,
    );
    final splitPane = provider.activePaneId;
    final primaryPane = provider.layoutState.primaryPaneId;
    provider.switchActivePane(primaryPane);
    expect(provider.activePaneId, primaryPane);

    final merged = provider.closeActivePane();

    expect(merged, WorkspaceMergeResult.ok);
    expect(provider.layoutState.paneOrder, [splitPane]);
    expect(provider.activePaneId, splitPane);
  });
}
