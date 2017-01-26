import 'package:flutter/material.dart';

/// Widget builder
typedef Widget WB(BuildContext context);

typedef void VCB();

void noop() {}

String _newHashKey(int oid, int wid) => '$oid:$wid';

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

abstract class PubSub {
  static RW _current = null;
  //static int _currentId = 0;
  //final int id = ++_currentId;
  //final List<Entry> _entries = [];
  final Map<String,Entry> _entries = {};

  void pub(int fid) {
    final int bit = fid == 0 ? 0 : (1 << (fid - 1));
    for (var entry in _entries.values) {
      var rw = StatefulWF._instances[entry.oid - 1].widgets[entry.wid - 1];
      if (fid == 0 || bit == (bit & rw._fieldBitset)) {
        rw._rs._update(noop);
      }
    }
  }

  void sub(int fid) {
    _current?.addTo(this, fid);
  }
}

class RS<T extends StatefulWidget> extends State<T> {
  final RW owner;
  final WB wb;
  RS(this.owner, this.wb);

  @override
  Widget build(BuildContext context) {
    PubSub._current = owner;
    var w = wb(context);
    PubSub._current = null;
    return w;
  }

  _update(VCB) {
    setState(VCB);
  }
}

class RW extends StatefulWidget {
  final StatefulWF owner;
  final WB wb;
  final int id;
  //Set<int> _subs;
  int _fieldBitset = 0;
  String _hashKey;
  RS _rs;
  RW(this.owner, this.wb, this.id, {Key key}) : super(key: key);

  @override
  State createState() {
    _rs = new RS<RW>(this, wb);

    return _rs;
  }

  RW copy(WB wb) {
    RW rw = new RW(owner, wb, id);
    //rw._subs = _subs;
    rw._fieldBitset = _fieldBitset;
    rw._hashKey = _hashKey;
    rw._rs = _rs;
    return rw;
  }

  Entry _putEntry() {
    return new Entry(owner.id, id);
  }

  void addTo(PubSub pubsub, int fid) {
    _hashKey ??= _newHashKey(owner.id, id);
    pubsub._entries.putIfAbsent(_hashKey, _putEntry);

    /*int rwId = owner._idMap[wb];
    RW rw;
    if (_subs == null) {
      _subs = new Set<int>();
      _subs.add(pubsub.id);
      pubsub._entries.add(new Entry(owner.id, id));
    } else if (_subs.add(pubsub.id)) {
      pubsub._entries.add(new Entry(owner.id, id));
    } else if (!identical((rw = owner.widgets[rwId - 1]), this)) {
      owner.widgets[rwId - 1] = this;
      _fieldBitset |= rw._fieldBitset;
      _rs ??= rw._rs;
    }*/

    if (fid != 0) {
      _fieldBitset |= (1 << (fid - 1));
    }
  }
}

abstract class WF {
  Widget $(WB wb);

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
  final Map<dynamic, int> _idMap = new Map.identity();

  int _idx = 0;
  StatefulWF() : id = ++_instanceId {
    _instances.add(this);
  }

  int _putId() => _idx;

  Widget $(WB wb) {
    RW rw;
    int i = 0;
    if (++_idx == (i = _idMap.putIfAbsent(wb, _putId))) {
      // new one
      rw = new RW(this, wb, i);
      widgets.add(rw);
    } else {
      _idx--;
      rw = widgets[i].copy(wb);
      widgets[i] = rw;
    }
    return rw;
  }

  _reset() {
    _idx = 0;
  }
}
