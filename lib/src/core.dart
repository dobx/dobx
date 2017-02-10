import 'package:flutter/material.dart';

/// Widget builder

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

abstract class PubSub {
  static RW _current = null;
  final Map<int,EntrySet> _mapping = {};

  void pub(int fid) {
    final EntrySet pe = _mapping[fid];
    if (pe == null) {
      return;
    }
    for (var entry in pe.entries) {
      StatefulWF._instances[entry.oid - 1].widgets[entry.wid - 1]._rs._update(noop);
    }
  }

  void sub(int fid) {
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

  _update(VoidCallback) {
    setState(VoidCallback);
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

abstract class WF {
  Widget $(WidgetBuilder wb, dynamic key, [ bool alwaysObserve = false ]);

  // TODO multiple separate roots
  static WF init(/*WF parent*/) {
    return StatefulWF._instances.length == 0 ? new StatefulWF() :
        StatefulWF._instances[0]._reset();
  }
}

// TODO multiple separate roots
class StatefulWF extends WF {
  static final List<StatefulWF> _instances = [];
  static int _instanceId = 0;

  final int id;
  final List<RW> widgets = [];
  final Map<dynamic, int> _idMap = {};

  int _idx = 0;
  StatefulWF() : id = ++_instanceId {
    _instances.add(this);
  }

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
