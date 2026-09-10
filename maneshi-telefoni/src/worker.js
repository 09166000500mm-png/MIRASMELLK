export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname === "/api/health") return json({ok:true, app:env.APP_NAME||"منشی تلفنی میراث ملک"});
    if (url.pathname === "/api/call" && request.method === "POST") return startCall(request,env);
    if (url.pathname === "/api/calls" && request.method === "GET") {
      const r=await env.DB.prepare("SELECT * FROM calls ORDER BY id DESC LIMIT 100").all();
      return json(r.results||[]);
    }
    if (url.pathname === "/voice" && request.method === "POST") return voice(request);
    if (url.pathname === "/voice/gather" && request.method === "POST") return gatherAnswer(request,env);
    return env.ASSETS.fetch(request);
  }
};

async function startCall(request,env){
  let b; try{b=await request.json()}catch{return json({error:"JSON نامعتبر"},400)}
  const phone=String(b.phone||"").trim();
  if(!phone)return json({error:"شماره مشتری وارد نشده"},400);
  if(!env.TWILIO_ACCOUNT_SID||!env.TWILIO_AUTH_TOKEN||!env.TWILIO_FROM_NUMBER)
    return json({error:"تنظیمات Twilio کامل نیست"},500);
  const ins=await env.DB.prepare("INSERT INTO calls(phone,status,started_at) VALUES(?,?,?)").bind(phone,"started",new Date().toISOString()).run();
  const id=ins.meta.last_row_id;
  const u=new URL("/voice",request.url); u.searchParams.set("callId",id);
  const p=new URLSearchParams({To:phone,From:env.TWILIO_FROM_NUMBER,Url:u.toString(),Method:"POST"});
  const r=await fetch(`https://api.twilio.com/2010-04-01/Accounts/${env.TWILIO_ACCOUNT_SID}/Calls.json`,{method:"POST",headers:{Authorization:"Basic "+btoa(env.TWILIO_ACCOUNT_SID+":"+env.TWILIO_AUTH_TOKEN),"Content-Type":"application/x-www-form-urlencoded"},body:p});
  const d=await r.json();
  if(!r.ok){await env.DB.prepare("UPDATE calls SET status=? WHERE id=?").bind("failed",id).run();return json({error:"Twilio خطا داد",details:d},502)}
  return json({ok:true,callId:id,twilioCallSid:d.sid});
}
function esc(s){return String(s).replaceAll("&","&amp;").replaceAll("<","&lt;").replaceAll(">","&gt;").replaceAll('"',"&quot;").replaceAll("'","&apos;")}
function say(t){return `<Say language="fa-IR">${esc(t)}</Say>`}
function xml(s){return new Response(s,{headers:{"Content-Type":"text/xml; charset=UTF-8"}})}
function voice(request){
  const u=new URL(request.url),id=u.searchParams.get("callId")||"";
  const n=new URL("/voice/gather",request.url);n.searchParams.set("callId",id);n.searchParams.set("field","property_type");
  return xml(`<?xml version="1.0" encoding="UTF-8"?><Response>${say("سلام. من منشی هوشمند دپارتمان میراث ملک هستم. برای تکمیل اطلاعات ملک چند سؤال کوتاه دارم.")}<Gather input="speech" language="fa-IR" speechTimeout="auto" action="${n}" method="POST">${say("لطفاً نوع ملک را بفرمایید؛ آپارتمان، ویلایی، تجاری، زمین یا گزینه دیگر؟")}</Gather>${say("پاسخی دریافت نشد. لطفاً بعداً دوباره تماس بگیرید.")}</Response>`);
}
async function gatherAnswer(request,env){
  const u=new URL(request.url),id=u.searchParams.get("callId"),field=u.searchParams.get("field");
  const f=await request.formData(),answer=String(f.get("SpeechResult")||"").trim();
  const q={
    property_type:["address","لطفاً آدرس کامل ملک را بفرمایید.","address"],
    address:["area","متراژ ملک چند متر است؟","area"],
    area:["year_built","سال ساخت ملک را بفرمایید.","year_built"],
    year_built:["floor","ملک در چه طبقه‌ای قرار دارد؟","floor"],
    floor:["units","ساختمان چند واحد دارد؟","units"],
    units:["price","قیمت یا مبلغ موردنظر مالک را بفرمایید.","price"],
    price:["notes","اگر توضیح یا شرط خاصی درباره ملک هست بفرمایید.","notes"]
  };
  if(q[field]&&id) await env.DB.prepare(`UPDATE calls SET ${q[field][2]}=? WHERE id=?`).bind(answer,id).run();
  if(field==="notes"){
    await env.DB.prepare("UPDATE calls SET status=?,finished_at=? WHERE id=?").bind("finished",new Date().toISOString(),id).run();
    return xml(`<?xml version="1.0" encoding="UTF-8"?><Response>${say("ممنونم. اطلاعات شما با موفقیت ثبت شد. همکاران دپارتمان میراث ملک با شما تماس می‌گیرند. روز خوبی داشته باشید.")}<Hangup/></Response>`);
  }
  const n=q[field],next=new URL("/voice/gather",request.url);next.searchParams.set("callId",id);next.searchParams.set("field",n[0]);
  return xml(`<?xml version="1.0" encoding="UTF-8"?><Response><Gather input="speech" language="fa-IR" speechTimeout="auto" action="${next}" method="POST">${say(n[1])}</Gather>${say("پاسخی دریافت نشد.")}</Response>`);
}
function json(d,s=200){return new Response(JSON.stringify(d),{status:s,headers:{"Content-Type":"application/json; charset=UTF-8"}})}
