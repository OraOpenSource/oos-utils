create or replace package oos_util_validation
  authid definer
as

  function is_number(p_str in varchar2)
    return boolean deterministic
  ;

  function is_number_yn(p_str in varchar2)
    return varchar2 deterministic
  ;

  function is_date
  (
    p_str in varchar2,
    p_date_format in varchar2
  )
    return boolean deterministic
  ;

  function is_date_yn
  (
    p_str in varchar2,
    p_date_format in varchar2
  )
    return varchar2 deterministic
  ;

  function is_equal
  (
    p_vala in varchar2,
    p_valb in varchar2
  )
    return boolean deterministic
  ;

  function is_equal_yn
  (
    p_vala in varchar2,
    p_valb in varchar2
  )
    return varchar2 deterministic
  ;
  
  function is_equal
  (
    p_vala in number,
    p_valb in number
  )
    return boolean deterministic
  ;

  function is_equal_yn
  (
    p_vala in number,
    p_valb in number
  )
    return varchar2 deterministic
  ;

  function is_equal
  (
    p_vala in date,
    p_valb in date
  )
    return boolean deterministic
  ;

  function is_equal_yn
  (
    p_vala in date,
    p_valb in date
  )
    return varchar2 deterministic
  ;

  function is_equal
  (
    p_vala in timestamp,
    p_valb in timestamp
  )
    return boolean deterministic
  ;

  function is_equal_yn
  (
    p_vala in timestamp,
    p_valb in timestamp
  )
    return varchar2 deterministic
  ;

  function is_equal
  (
    p_vala in timestamp with time zone,
    p_valb in timestamp with time zone
  )
    return boolean deterministic
  ;

  function is_equal_yn
  (
    p_vala in timestamp with time zone,
    p_valb in timestamp with time zone
  )
    return varchar2 deterministic
  ;

  function is_equal
  (
    p_vala in timestamp with local time zone,
    p_valb in timestamp with local time zone
  )
    return boolean deterministic
  ;

  function is_equal_yn
  (
    p_vala in timestamp with local time zone,
    p_valb in timestamp with local time zone
  )
    return varchar2 deterministic
  ;

  function is_equal
  (
    p_vala in boolean,
    p_valb in boolean
  )
    return boolean deterministic
  ;

end oos_util_validation;
/
