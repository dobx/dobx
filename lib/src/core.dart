import 'package:flutter/material.dart';

/// Widget builder
typedef Widget WB(BuildContext context);

typedef void VCB();

void _noop() {}

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
  final Map<String, Entry> _entries = {};

  void pub(int fid) {
    final int bit = fid == 0 ? 0 : (1 << (fid - 1));
    for (var entry in _entries.values) {
      var rw = StatefulWF._instances[entry.oid - 1].widgets[entry.wid - 1];
      if (fid == 0 || bit == (bit & rw._fieldBitset)) {
        rw._rs._update(_noop);
      }
    }
  }

  void sub(int fid) {
    _current?.addTo(_entries, fid);
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
    rw._fieldBitset = _fieldBitset;
    rw._hashKey = _hashKey;
    rw._rs = _rs;
    return rw;
  }

  void addTo(Map<String,Entry> entries, int fid) {
    _hashKey ??= _newHashKey(owner.id, id);

    Entry entry = entries[_hashKey];
    if (entry == null) {
      entry = new Entry(owner.id, id);
      entries[_hashKey] = entry;
    }

    if (fid != 0) {
      _fieldBitset |= (1 << (fid - 1));
    }
  }
}

class StatefulWF {
  static final List<StatefulWF> _instances = [];
  static int _instanceId = 0;

  final int id;
  final List<RW> widgets = [];
  int _idx = 0;
  bool _replace = false;
  WB _first;
  StatefulWF() : id = ++_instanceId {
    _instances.add(this);
  }

  $(WB wb) {
    RW rw;
    if (_first == wb) {
      // first call after reload
      _replace = true;
      _idx = 0;
      rw = widgets[_idx].copy(wb);
      widgets[_idx++] = rw;
    } else if (_replace) {
      rw = widgets[_idx].copy(wb);
      widgets[_idx++] = rw;
    } else {
      // initial
      rw = new RW(this, wb, ++_idx);
      widgets.add(rw);
      _first ??= wb;
    }
    return rw;
  }
}
