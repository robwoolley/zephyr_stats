from xml.etree import ElementTree


def to_float(val):
    if val is None:
        return None

    return float(val)


class Parser(object):

    def parse(self, source):
        xml = ElementTree.parse(source)
        root = xml.getroot()
        return self.parse_root(root)

    def parse_root(self, root):
        ts = []
        if root.tag == 'testsuites':
            for subroot in root:
                ts.extend(self.parse_testsuite(subroot, ts))
        else:
            ts.extend(self.parse_testsuite(root, ts))

        tr = {
            'time': to_float(root.attrib.get('time'))
        }

        return (ts, tr)

    def parse_testsuite(self, root, ts):
        assert root.tag == 'testsuite'
        name = root.attrib.get('name')
        package = root.attrib.get('package')
        for el in root:
            if el.tag == 'testcase':
                yield self.parse_testcase(el, ts, default_name=name)

    def parse_testcase(self, el, ts, default_name):
        tc_classname = el.attrib.get('classname') or default_name
        tc = {
            'classname': tc_classname,
            'name': el.attrib['name'],
            'time': to_float(el.attrib.get('time')),
            'file': el.attrib.get('file'),
        }
        for e in el:
            # error takes over failure in JUnit 4
            if e.tag in ('failure', 'error', 'skipped'):
                tc['result'] = e.tag
                tc['typename'] = e.attrib.get('type')
                break
        else:
            tc['result'] = 'success'

        return tc


def parse(source):
    return Parser().parse(source)
