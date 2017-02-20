require 'melt'

require 'timecop'

module Melt
  module Formatters
    RSpec.describe Netfilter::Rule do
      it 'formats simple rules' do
        rule = Rule.new(action: :pass, dir: :in, proto: :tcp, to: { host: nil, port: 80 })
        expect(subject.emit_rule(rule)).to eq('-A INPUT -p tcp --dport 80 -j ACCEPT')

        rule = Rule.new(action: :pass, dir: :in, on: 'lo')
        expect(subject.emit_rule(rule)).to eq('-A INPUT -i lo -j ACCEPT')

        rule = Rule.new(action: :block, dir: :in, on: '!lo', to: { host: IPAddress.parse('127.0.0.0/8') })
        expect(subject.emit_rule(rule)).to eq('-A INPUT ! -i lo -d 127.0.0.0/8 -j DROP')

        rule = Rule.new(action: :pass, dir: :out)
        expect(subject.emit_rule(rule)).to eq('-A OUTPUT -j ACCEPT')
      end

      it 'returns packets when instructed so' do
        rule = Rule.new(action: :block, return: true, dir: :in, proto: :icmp)
        expect(subject.emit_rule(rule)).to eq('-A INPUT -p icmp -j RETURN')
      end

      it 'formats forward rules' do
        rule = Rule.new(action: :pass, dir: :fwd, in: 'eth1', out: 'ppp0', from: { host: IPAddress.parse('192.168.0.0/24') })
        expect(subject.emit_rule(rule)).to eq('-A FORWARD -i eth1 -o ppp0 -s 192.168.0.0/24 -j ACCEPT')
      end

      it 'formats dnat rules' do
        rule = Rule.new(action: :pass, dir: :in, on: 'ppp0', proto: :tcp, to: { port: 80 }, rdr_to: { host: IPAddress.parse('192.168.0.42') })
        expect(subject.emit_rule(rule)).to eq('-A PREROUTING -i ppp0 -p tcp --dport 80 -j DNAT --to-destination 192.168.0.42')
      end

      it 'formats dnat rules ignoring same port' do
        rule = Rule.new(action: :pass, dir: :in, on: 'ppp0', proto: :tcp, to: { port: 80 }, rdr_to: { host: IPAddress.parse('192.168.0.42'), port: 80 })
        expect(subject.emit_rule(rule)).to eq('-A PREROUTING -i ppp0 -p tcp --dport 80 -j DNAT --to-destination 192.168.0.42')
      end

      it 'formats dnat rules with port' do
        rule = Rule.new(action: :pass, dir: :in, on: 'ppp0', proto: :tcp, to: { port: 80 }, rdr_to: { host: IPAddress.parse('192.168.0.42'), port: 8080 })
        expect(subject.emit_rule(rule)).to eq('-A PREROUTING -i ppp0 -p tcp --dport 80 -j DNAT --to-destination 192.168.0.42:8080')
      end

      it 'formats redirect rules' do
        rule = Rule.new(action: :pass, dir: :in, on: 'eth0', proto: :tcp, to: { port: 80 }, rdr_to: { host: IPAddress.parse('127.0.0.1/32'), port: 3128 })
        expect(subject.emit_rule(rule)).to eq('-A PREROUTING -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 3128')
      end

      it 'formats nat rules' do
        rule = Rule.new(action: :pass, dir: :out, on: 'ppp0', nat_to: IPAddress.parse('198.51.100.72'))
        expect(subject.emit_rule(rule)).to eq('-A POSTROUTING -o ppp0 -j MASQUERADE')
      end
    end

    RSpec.describe Netfilter::Ruleset do
      context 'ruleset' do
        before do
          Timecop.freeze('2000-01-01 00:00:00')
        end
        it 'formats a simple lan network rules' do
          dsl = Melt::Dsl.new
          dsl.eval_network(File.join('spec', 'fixtures', 'simple_lan_network.rb'))
          rules = dsl.ruleset_for('gw')
          expect(subject.emit_ruleset(rules, :block)).to eq <<-EOT
# Generated by melt v1.0.0 on Sat Jan  1 00:00:00 2000
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A PREROUTING -i ppp0 -p tcp --dport 80 -j DNAT --to-destination 192.168.1.80
-A POSTROUTING -o ppp0 -j MASQUERADE
COMMIT
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT DROP [0:0]
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
-A FORWARD -i ppp0 -p tcp -d 192.168.1.80 --dport 80 -j ACCEPT
-A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A OUTPUT -p udp -d 192.168.0.53 --dport 53 -j ACCEPT
-A OUTPUT -p udp -d 192.168.1.53 --dport 53 -j ACCEPT
COMMIT
EOT
          rules = dsl.ruleset_for('www')
          expect(subject.emit_ruleset(rules, :block)).to eq <<-EOT
# Generated by melt v1.0.0 on Sat Jan  1 00:00:00 2000
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT DROP [0:0]
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT -p tcp --dport 80 -j ACCEPT
-A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
-A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A OUTPUT -p udp -d 192.168.0.53 --dport 53 -j ACCEPT
-A OUTPUT -p udp -d 192.168.1.53 --dport 53 -j ACCEPT
COMMIT
EOT
        end
      end
    end
  end
end
