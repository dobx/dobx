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

import 'package:flutter/material.dart';

void noop() {}

//String _newHashKey(int oid, int wid) => '$oid:$wid';

class Entry {
  final int oid, wid;
  //final String hashKey;
  const Entry(this.oid, this.wid);//: hashKey = newHashKey(oid, wid);

  /*@override
  get hashCode => hashKey.hashCode;

  @override
  String toString() => hashKey;

  bool operator ==(other) => hashKey == other.toString();*/
}

class EntrySet {
  final List<Entry> entries = [];
  int oidBS = 0, widBS = 0;
}

class PubSub {
  static RW _current = null;
  final Map<int,EntrySet> _mapping = {};

  void $pub(int fid) {
    final EntrySet pe = _mapping[fid];
    if (pe == null) {
      return;
    }
    for (var entry in pe.entries) {
      WF._instances[entry.oid - 1].widgets[entry.wid - 1]._rs._update(noop);
    }
  }

  void $sub(int fid) {
    _current?.addTo(this, fid);
  }
}

class RS extends State<RW> {
  final RW owner;
  final WidgetBuilder wb;
  bool skipRecord = false;
  RS(this.owner, this.wb);

  @override
  Widget build(BuildContext context) {
    if (skipRecord) return wb(context);

    PubSub._current = owner;
    var w = wb(context);
    PubSub._current = null;

    if (!owner.alwaysRecord) skipRecord = true;

    return w;
  }

  _update(VoidCallback cb) {
    setState(cb);
  }
}

EntrySet newEntrySet() {
  return new EntrySet();
}

class RW extends StatefulWidget {
  final StatefulWF owner;
  final WidgetBuilder wb;
  final int id;
  final bool alwaysRecord;
  final int oidFlag, widFlag;
  //Set<int> _subs;
  int _fieldBitset = 0;
  //String _hashKey;
  RS _rs;
  RW(this.owner, this.wb, this.id, this.alwaysRecord, {Key key}) :
        oidFlag = (1 << owner.id - 1),
        widFlag = (1 << id - 1),
        super(key: key);

  @override
  State createState() {
    _rs = new RS(this, wb);

    return _rs;
  }

  RW copy(WidgetBuilder wb) {
    RW rw = new RW(owner, wb, id, alwaysRecord);
    //rw._subs = _subs;
    rw._fieldBitset = _fieldBitset;
    //rw._hashKey = _hashKey;
    rw._rs = _rs;
    // reset
    _rs.skipRecord = false;
    return rw;
  }

  void addTo(PubSub pubsub, int fid) {
    //_hashKey ??= _newHashKey(owner.id, id);
    EntrySet es = pubsub._mapping.putIfAbsent(fid, newEntrySet);
    if (oidFlag == (oidFlag & es.oidBS) && widFlag == (widFlag & es.widBS)) {
      return;
    }

    es.oidBS |= oidFlag;
    es.widBS |= widFlag;
    es.entries.add(new Entry(owner.id, id));
  }
}

/// Widget Factory
abstract class WF {
  static final List<StatefulWF> _instances = new List<StatefulWF>(64);

  Widget $(WidgetBuilder wb, dynamic key, [ bool alwaysObserve = false ]);

  /// Get by index (0-63).
  static WF get(int idx) {
    StatefulWF wf = _instances[idx];
    if (wf == null) {
      _instances[idx] = wf = new StatefulWF(idx + 1);
    }
    return wf;
  }
}

// TODO multiple separate roots
class StatefulWF extends WF {

  final int id;
  final List<RW> widgets = [];
  final Map<dynamic, int> _idMap = {};

  int _idx = 0;
  StatefulWF(this.id);

  int _putId() => _idx;

  Widget $(WidgetBuilder wb, dynamic key, [ bool alwaysObserve = false ]) {
    RW rw;
    int i = 0;
    if (++_idx == (i = _idMap.putIfAbsent(key, _putId))) {
      // new one
      rw = new RW(this, wb, i, alwaysObserve);
      widgets.add(rw);
    } else {
      _idx--;
      i--;
      rw = widgets[i].copy(wb);
      widgets[i] = rw;
    }
    return rw;
  }

  StatefulWF _reset() {
    // TODO
    return this;
  }
}
