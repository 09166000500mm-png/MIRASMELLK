export const QUESTIONS = [
{id:'address',title:'آدرس کامل ملک',prompt:'لطفاً آدرس کامل ملک را بفرمایید.'},
{id:'area',title:'متراژ زیربنا و زمین',prompt:'متراژ زیربنا و در صورت وجود، متراژ زمین چقدر است؟'},
{id:'year',title:'سال ساخت',prompt:'سال ساخت ملک را می‌فرمایید؟'},
{id:'floor',title:'طبقه و تعداد واحد',prompt:'ملک در چه طبقه‌ای است و ساختمان چند واحد دارد؟'},
{id:'amenities',title:'امکانات',prompt:'آسانسور، پارکینگ و انباری دارد؟ لطفاً توضیح دهید.'},
{id:'deal',title:'نوع معامله و مبلغ',prompt:'نوع معامله و مبلغ موردنظر چقدر است؟'}
] as const;
export type QuestionId=typeof QUESTIONS[number]['id'];
export type PropertyRecord={id:string;createdAt:string;address:string;area:string;year:string;floor:string;amenities:string;deal:string;transcript?:string;audioUri?:string};