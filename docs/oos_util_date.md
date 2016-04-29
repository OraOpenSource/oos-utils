# OOS_UTIL_DATE

- [DATE2EPOCH Function](#date2epoch)
- [EPOCH2DATE Function](#epoch2date)








 
## DATE2EPOCH Function<a name="date2epoch"></a>


<p>
<p>Coverts date to Unix Epoch time</p>
</p>

### Syntax
```plsql
function date2epoch(
  p_date in date)
  return number
```

### Parameters
Name | Description
--- | ---
`p_date` | Date to convert to Epoch format
*return* | Unix Epoch time
 
 


### Example
```plsql

select oos_util_date.date2epoch(sysdate)
from dual;

OOS_UTIL_DATE.DATE2EPOCH(SYSDATE)
---------------------------------
                       1461663997
```



 
## EPOCH2DATE Function<a name="epoch2date"></a>


<p>
<p>Converts Unix linux time to Oracle date</p>
</p>

### Syntax
```plsql
function epoch2date(
  p_epoch in number)
  return date
```

### Parameters
Name | Description
--- | ---
`p_epoch` | Epoch Unix date (number)
*return* | date
 
 


### Example
```plsql

select oos_util_date.epoch2date(1461663982)
from dual;

OOS_UTIL_DATE.EPOCH2DATE(1461663982)
------------------------------------
26-APR-2016 12:46:22
```



 
