
String newHashKey(int oid, int wid) => '$oid:$wid';

class Entry {
  final int oid, wid;
  //final String hashKey;
  Entry(this.oid, this.wid);//: hashKey = newHashKey(oid, wid);

  /*@override
  get hashCode => hashKey.hashCode;

  @override
  String toString() => hashKey;

  bool operator ==(other) => hashKey == other.toString();*/
}

abstract class PubSub {
  static RW current = null;
  final Map<String, Entry> entries = {};

  void pub(int fid) {
    int flags = fid == 0 ? 0 : (1 << (fid - 1));
    for (var entry in entries.values) {
      var rw = RWFactory._instances[entry.oid - 1].widgets[entry.wid - 1];
      if (fid == 0 || flags == (flags & rw.fieldFlags)) {
        rw.rs.setState(noop);
      }
    }
  }

  /*int sub(RW w, int i) {
    var idx = subs.length;

    if (w.key != null)
      subs.add(w);
    else
      idx = -1;

    return idx;
  }*/

  void sub(int fid) {
    current?.addTo(entries, fid);
  }
}

/// Widget builder
typedef Widget WB(BuildContext context);

class RS<T extends StatefulWidget> extends State<T> {
  final RW owner;
  final WB wb;
  RS(this.owner, this.wb);

  @override
  Widget build(BuildContext context) {
    PubSub.current = owner;
    var w = wb(context);
    PubSub.current = null;
    return w;
  }
}

class RW extends StatefulWidget {
  final RWFactory owner;
  final WB wb;
  final int id;
  int fieldFlags = 0;
  RS rs;
  int fid;
  String hashKey;
  RW(this.owner, this.wb, this.id, {Key key}) : super(key: key);

  @override
  State createState() {
    rs = new RS<RW>(this, wb);

    return rs;
  }

  RW copy(WB wb) {
    RW rw = new RW(owner, wb, id);
    rw.hashKey = hashKey;
    rw.rs = rs;
    return rw;
  }

  void addTo(Map<String,Entry> entries, int fid) {
    hashKey ??= newHashKey(owner.id, id);

    Entry entry = entries[hashKey];
    if (entry == null) {
      entry = new Entry(owner.id, id);
      entries[hashKey] = entry;
    }

    if (fid != 0) {
      fieldFlags |= (1 << (fid - 1));
    }
  }
}

class RWFactory {
  static final List<RWFactory> _instances = [];
  static int _instanceId = 0;

  final int id;
  final List<RW> widgets = [];
  int idx = 0;
  WB first;
  RWFactory() : id = ++_instanceId {
    _instances.add(this);
  }

  $(WB wb) {
    RW rw;
    if (first == wb) {
      print('repaint');
      idx = 0;
      rw = widgets[idx].copy(wb);
      widgets[idx++] = rw;
    } else {
      rw = new RW(this, wb, ++idx);
      widgets.add(rw);
      first ??= wb;
    }

    print('idx: $idx');

    return rw;
  }
}
