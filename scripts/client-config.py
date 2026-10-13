"""Read the existing client connection config; edit only its server address.

ENC format verified against Michael-K-GH/libcozip, commit
eff32a6bc2964703da06b03e094acbf6a4e5ef0e (MIT).
No executable, anticheat or integrity-check options are modified.
"""
import argparse
import hashlib
import pathlib
import re
import struct
import zlib

KEY = bytes.fromhex('92656757')

def unpack(raw, key=KEY):
    size = struct.unpack('<I', raw[:4])[0]
    if not 1 <= size <= 1024 * 1024:
        raise ValueError('Unexpected configuration size')
    compressed = bytearray(raw[4:])
    for i in range(4):
        compressed[i] ^= key[i]
    inflater = zlib.decompressobj(-15)
    plain = inflater.decompress(compressed, size + 1)
    if len(plain) != size or not inflater.eof or inflater.unused_data:
        raise ValueError('Invalid ENC size or stream')
    return plain

def pack(plain, key=KEY):
    compressor = zlib.compressobj(9, zlib.DEFLATED, -15)
    compressed = bytearray(compressor.compress(plain) + compressor.flush())
    for i in range(4):
        compressed[i] ^= key[i]
    return struct.pack('<I', len(plain)) + compressed

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('client', type=pathlib.Path)
    parser.add_argument(
        '--config',
        type=pathlib.Path,
        help='relative configuration path; defaults to Data/language.enc',
    )
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--xor-hex', default=KEY.hex(), help='four-byte ENC configuration key in hex')
    args = parser.parse_args()
    key = bytes.fromhex(args.xor_hex)
    if len(key) != 4:
        parser.error('--xor-hex must contain exactly four bytes')
    path = args.client / (args.config or pathlib.Path('Data/language.enc'))
    if not path.is_file():
        raise FileNotFoundError(path)
    raw = path.read_bytes()
    plain = unpack(raw, key)
    if unpack(pack(plain, key), key) != plain:
        raise ValueError('Configuration roundtrip failed')
    print(plain.decode('latin1'))
    if args.apply:
        # Only replace the observed IP field; preserve all remaining bytes/options.
        pattern = rb'(?mi)^(\d+_(?:Login(?:EX|Test)?_Addr|chsAddr)[ \t]*=[ \t]*)([^\r\n]+)'
        fields = re.findall(pattern, plain)
        if not fields or b'1_Login_Addr=' not in plain:
            raise ValueError('Expected known login address fields; refusing edit')
        updated = re.sub(pattern, lambda m: m[1] + b'127.0.0.1', plain)
        if updated == plain:
            print('Already configured for localhost')
            return
        packed = pack(updated, key)
        if unpack(packed, key) != updated:
            raise ValueError('Updated configuration verification failed')
        backup = path.with_name('language.enc.local-backup')
        if not backup.exists():
            with backup.open('xb') as file:
                file.write(raw)
        temp = path.with_name('language.enc.local-tmp')
        with temp.open('xb') as file:
            file.write(packed)
        temp.replace(path)
        print('Saved localhost IP; backup:', backup)
        print('SHA256:', hashlib.sha256(packed).hexdigest())

if __name__ == '__main__':
    main()
