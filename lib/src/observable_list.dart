// ========================================================================
// Copyright 2017 David Yu
// ------------------------------------------------------------------------
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// ========================================================================

// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:collection/collection.dart';
import './core.dart' show PubSub;

/// Notifies subscribers on mutations.
abstract class ObservableList<E> implements List<E> {
  /// An empty observable list that never has changes.
  /*static const ObservableList EMPTY = const _ObservableUnmodifiableList(
    const [],
  );*/

  /// Creates an observable list of the given [length].
  factory ObservableList([int length]) {
    final list = length != null ? new List<E>(length) : <E>[];
    return new ObservableDelegatingList(list);
  }

  /// Create a new observable list.
  ///
  /// Optionally define a [list] to use as a backing store.
  factory ObservableList.delegate(List<E> list) {
    return new ObservableDelegatingList(list);
  }

  /// Create a new observable list from [elements].
  factory ObservableList.from(Iterable<E> elements) {
    return new ObservableDelegatingList(elements.toList());
  }

  List<E> sub1();

  /// Create new unmodifiable list from [list].
  ///
  /// [ObservableList.changes] and [ObservableList.listChanges] both always
  /// return an empty stream, and mutating or adding change records throws an
  /// [UnsupportedError].
  /*factory ObservableList.unmodifiable(
    List<E> list,
  ) {
    if (list is! UnmodifiableListView<E>) {
      list = new List<E>.unmodifiable(list);
    }
    return new _ObservableUnmodifiableList<E>(list);
  }*/
}

class ObservableDelegatingList<E> extends DelegatingList<E> with PubSub
    implements ObservableList<E> {

  ObservableDelegatingList(List<E> store) : super(store);

  @override
  List<E> sub1() {
    sub(1);
    return this;
  }

  @override
  List<E> sublist(int start, [int end]) {
    return start == null ? sub1() : super.sublist(start, end);
  }

  // List

  @override
  operator []=(int index, E newValue) {
    super[index] = newValue;
    pub(1);
  }

  @override
  void add(E value) {
    super.add(value);
    pub(1);
  }

  @override
  void addAll(Iterable<E> values) {
    super.addAll(values);
    pub(1);
  }

  @override
  void clear() {
    super.clear();
    pub(1);
  }

  @override
  void fillRange(int start, int end, [E value]) {
    super.fillRange(start, end, value);
    pub(1);
  }

  @override
  void insert(int index, E element) {
    super.insert(index, element);
    pub(1);
  }

  @override
  void insertAll(int index, Iterable<E> values) {
    super.insertAll(index, values);
    pub(1);
  }

  @override
  set length(int newLength) {
    final currentLength = this.length;
    if (currentLength == newLength) {
      return;
    }
    super.length = newLength;
    pub(1);
  }

  @override
  bool remove(Object element) {
    for (var i = 0; i < this.length; i++) {
      if (this[i] == element) {
        removeAt(i);
        pub(1);
        return true;
      }
    }
    return false;
  }

  @override
  E removeAt(int index) {
    E el = super.removeAt(index);
    pub(1);
    return el;
  }

  @override
  E removeLast() {
    final E element = super.removeLast();
    pub(1);
    return element;
  }

  @override
  void removeRange(int start, int end) {
    super.removeRange(start, end);
    pub(1);
  }

  @override
  void removeWhere(bool test(E element)) {
    // Produce as few change records as possible - if we have multiple removals
    // in a sequence we want to produce a single record instead of a record for
    // every element removed.
    int firstRemovalIndex;
    int removed = 0;
    for (var i = 0; i < length; i++) {
      var element = this[i];
      if (test(element)) {
        if (firstRemovalIndex == null) {
          // This is the first item we've removed for this sequence.
          firstRemovalIndex = i;
        }
      } else if (firstRemovalIndex != null) {
        // We have a previous sequence of removals, but are not removing more.
        super.removeRange(firstRemovalIndex, i--);
        removed++;
        firstRemovalIndex = null;
      }
    }

    // We have have a pending removal that was never finished.
    if (firstRemovalIndex != null) {
      super.removeRange(firstRemovalIndex, length);
      removed++;
    }

    if (removed != 0) pub(1);
  }

  @override
  void replaceRange(int start, int end, Iterable<E> newContents) {
    // This could be optimized not to emit two change records but would require
    // code duplication with these methods. Since this is not used extremely
    // often in my experience OK to just defer to these methods.
    //removeRange(start, end);
    //insertAll(start, newContents);

    super.replaceRange(start, end, newContents);
    pub(1);
  }

  @override
  void retainWhere(bool test(E element)) {
    // This should be functionally the opposite of removeWhere.
    removeWhere((E element) => !test(element));
  }

  @override
  void setAll(int index, Iterable<E> elements) {
    /*if (!hasObservers) {
      super.setAll(index, elements);
      return;
    }
    // Manual invocation of this method is required to get nicer change events.
    var i = index;
    final removed = <E>[];
    for (var e in elements) {
      removed.add(this[i]);
      super[i++] = e;
    }
    if (removed.isNotEmpty) {
      notifyListChange(index, removed: removed, addedCount: removed.length);
    }*/
    super.setAll(index, elements);
    pub(1);
  }

  @override
  void setRange(int start, int end, Iterable<E> elements, [int skipCount = 0]) {
    /*if (!hasObservers) {
      super.setRange(start, end, elements, skipCount);
      return;
    }
    final iterator = elements.skip(skipCount).iterator..moveNext();
    final removed = <E>[];
    for (var i = start; i < end; i++) {
      removed.add(super[i]);
      super[i] = iterator.current;
      iterator.moveNext();
    }
    if (removed.isNotEmpty) {
      notifyListChange(start, removed: removed, addedCount: removed.length);
    }*/
    super.setRange(start, end, elements, skipCount);
    pub(1);
  }
}

/*class _ObservableUnmodifiableList<E> extends DelegatingList<E>
    implements ObservableList<E> {
  const _ObservableUnmodifiableList(List<E> list) : super(list);

  @override
  Stream<List<ChangeRecord>> get changes => const Stream.empty();

  @override
  bool deliverChanges() => false;

  @override
  bool deliverListChanges() => false;

  @override
  void discardListChanges() {}

  @override
  final bool hasListObservers = false;

  @override
  final bool hasObservers = false;

  @override
  Stream<List<ListChangeRecord<E>>> get listChanges => const Stream.empty();

  @override
  void notifyChange([ChangeRecord change]) {
    throw new UnsupportedError('Not modifiable');
  }

  @override
  void notifyListChange(
    int index, {
    List<E> removed: const [],
    int addedCount: 0,
  }) {
    throw new UnsupportedError('Not modifiable');
  }

  @override
  *//*=T*//* notifyPropertyChange*//*<T>*//*(
    Symbol field,
    *//*=T*//*
    oldValue,
    *//*=T*//*
    newValue,
  ) {
    throw new UnsupportedError('Not modifiable');
  }

  @override
  void observed() {}

  @override
  void unobserved() {}
}*/
