create or replace package oos_util_crypto
as
  -- TODO mdsouza: use gc???

  -- Hash Functions
  hash_md4 constant pls_integer := 1;
  hash_md5 constant pls_integer := 2;
  hash_sh1 constant pls_integer := 3;
  hash_sh224 constant pls_integer := 11;
  hash_sh256 constant pls_integer := 4;
  hash_sh384 constant pls_integer := 5;
  hash_sh512 constant pls_integer := 6;
  hash_ripemd160 constant pls_integer := 15;
  -- MAC Functions
  hmac_md4 constant pls_integer := 0;
  hmac_md5 constant pls_integer := 1;
  hmac_sh1 constant pls_integer := 2;
  hmac_sh224 constant pls_integer := 10;
  hmac_sh256 constant pls_integer := 3;
  hmac_sh384 constant pls_integer := 4;
  hmac_sh512 constant pls_integer := 5;
  hmac_ripemd160 constant pls_integer := 14;
  -- Block Cipher Algorithms
  encrypt_des constant pls_integer := 1;  -- 0x0001
  encrypt_3des_2key constant pls_integer := 2;  -- 0x0002
  encrypt_3des constant pls_integer := 3;  -- 0x0003
  encrypt_aes constant pls_integer := 4;  -- 0x0004
  encrypt_pbe_md5des constant pls_integer := 5;  -- 0x0005
  encrypt_aes128 constant pls_integer := 6;  -- 0x0006
  encrypt_aes192 constant pls_integer := 7;  -- 0x0007
  encrypt_aes256 constant pls_integer := 8;  -- 0x0008
  -- Block Cipher Chaining Modifiers
  chain_cbc constant pls_integer := 256;  -- 0x0100
  chain_cfb constant pls_integer := 512;  -- 0x0200
  chain_ecb constant pls_integer := 768;  -- 0x0300
  chain_ofb constant pls_integer := 1024;  -- 0x0400
  chain_ofb_real constant pls_integer := 1280;  -- 0x0500
  -- Block Cipher Padding Modifiers
  pad_pkcs5 constant pls_integer := 4096;  -- 0x1000
  pad_none constant pls_integer := 8192;  -- 0x2000
  pad_zero constant pls_integer := 12288;  -- 0x3000
  pad_orcl constant pls_integer := 16384;  -- 0x4000
  pad_oneandzeroes constant pls_integer := 20480;  -- 0x5000
  pad_ansi_x923 constant pls_integer := 24576;  -- 0x6000
  -- Stream Cipher Algorithms
  encrypt_rc4 constant pls_integer := 129;  -- 0x0081

  -- TODO mdsouza: formatting below
--
function hash( src raw, typ pls_integer )
return raw;
--
function mac( src raw, typ pls_integer, key raw )
return raw;
--
function randombytes( number_bytes positive )
return raw;
--
function encrypt( src raw, typ pls_integer, key raw, iv raw := null )
return raw;
--
function decrypt( src raw, typ pls_integer, key raw, iv raw := null )
return raw;
--
end oos_util_crypto;

/
