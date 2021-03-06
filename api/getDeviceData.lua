--[[
@apiDefine Response
@apiParam(response){string} Message 响应信息，接口请求success或failed返回相关信息
@apiParam(response){bool} Successful 是否成功。通过该字段可以判断请求是否到达.
--]]
--[[
@api {POST} http://hcwzq.cn/api/getDeviceData.json?uid=*&did=*[&StartTime=*][&EndTime=*] getDeviceData
@apiName getDeviceData
@apiGroup All
@apiVersion 1.0.1
@apiDescription 获取指定设备的全部传感器数据

@apiParam {string} uid 唯一ID值，32位md5
@apiParam {string} did 唯一设备ID值，32位md5
@apiParam {string} [StartTime] 选择数据区间，开始时间，默认：2015-09-01 00:00:00，格式：2015-09-01 00:00:00
@apiParam {string} [EndTime] 选择数据区间，结束时间，默认：当前时间，格式：2015-09-01 00:00:00


@apiParam {json} response 响应数据
@apiUse Response


@apiParamExample Example:
POST http://hcwzq.cn/api/getDeviceData.json?uid=c81e728d9d4c2f636f067f89cc14862c&did=eccbc87e4b5ce2fe28308fd9f2a7baf3&StartTime=2016-09-01 00:00:00&EndTime=2016-10-01 00:00:00

@apiSuccessExample {json} Success-Response:
HTTP/1.1 200 OK
{
"1":[{
	"timestamp":"2016-10-20 14:50:30",
	"sensor":"weight",
	"value":56
}],
"Message":"success",
"Successful":true
}

@apiErrorExample {json} Error-Response:
HTTP/1.1 200 OK  
{
    "Successful":false,
    "Message": "uid error or did error or not exist"
}

--]]



--版本1
-- curl -i  '127.0.0.1/api/getDeviceData.json?uid=001&did=001'
--待续的参数    默认值
-- StartTime 否	2015-09-01	 datetime	 小于当前时间	 起始时间
-- EndTime	 否	当前时间	 datetime		 截止时间
local redis  = require("lua.db_redis.db_base")
local common = require("lua.comm.common")
local red    = redis:new()
local db_handle = require("lua.db_redis.db")

local args = ngx.req.get_uri_args()
if not args.uid or not args.did then
	ngx.log(ngx.WARN,"post args error")
	ngx.exit(ngx.HTTP_BAD_REQUEST)
end

local response = {}
response.Successful = true
response.Message    = "success"

local StartTime = args.StartTime or "2015-09-01 00:00:00"
local EndTime   = args.EndTime   or ngx.localtime()

ngx.log(ngx.ERR, "StartTime:", StartTime)
--2015-09-01 時間格式要求嚴格
--2015-09-01 00:00:00 \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}
StartTime = ngx.re.match(StartTime, [[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}]])
EndTime   = ngx.re.match(EndTime, [[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}]])

if not StartTime or not EndTime then
	response.Successful = false
	response.Message    = "Error time format"
	ngx.say(common.json_encode(response))
	return
end

local res, err = red:hget("uid:".. args.uid,"did:" .. args.did)
if err then
	ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
end

if not res then
	response.Successful = false
	response.Message    = "uid error or did error or not exist"
	ngx.say(common.json_encode(response))
	return
end

local res_data = (common.json_decode(res))["data"]

res_data = db_handle.select_data(StartTime, EndTime, res_data)

table.insert(response,res_data)
ngx.say(common.json_encode(response))
