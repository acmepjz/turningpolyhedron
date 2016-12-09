#include "MyFormat.h"

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

static char m_sBuffer[1024];

MyFormat::MyFormat()
:m_nIndex(0)
,m_nPosition(0)
,m_bDirty(false)
{
	m_tCurrent.Width=-3;
	m_tCurrent.Precision=-3;
}

MyFormat::MyFormat(const u8string& fmt)
:m_nIndex(0)
,m_nPosition(0)
,m_bDirty(false)
{
	m_tCurrent.Width=-3;
	m_tCurrent.Precision=-3;

	appendFormat(fmt);
}

void MyFormat::append(int32_t n,bool bSigned){
	int m=m_Placeholder.size();
	if(m_nIndex>=m) return;

	if(m_nPosition<0){
		if(m_tCurrent.Width==-3 || m_tCurrent.Precision==-3){
			m_tCurrent=m_Placeholder[m_nIndex];
		}

		//check if read arguments from input data
		if(m_tCurrent.Width==-1){
			m_tCurrent.Width=(int)n;
			if(m_tCurrent.Width<=0) m_tCurrent.Width=-2;
		}else if(m_tCurrent.Precision==-1){
			m_tCurrent.Precision=(int)n;
			if(m_tCurrent.Precision<0) m_tCurrent.Precision=-2;
		}else{
			appendByPosition(m_nIndex,n,bSigned);

			m_nIndex++;
			m_tCurrent.Width=-3;
			m_tCurrent.Precision=-3;
		}
	}else{
		int ppp=(++m_nPosition),idx=m;

		for(int i=m_nIndex;i<m;i++){
			int p=m_Placeholder[i].Position;

			if(p==ppp){
				m_tCurrent=m_Placeholder[i];
				appendByPosition(i,n,bSigned);
			}else if(p>ppp && i<idx){
				idx=i;
			}
		}

		m_nIndex=idx;
	}
}

void MyFormat::append(int64_t n,bool bSigned){
	int m=m_Placeholder.size();
	if(m_nIndex>=m) return;

	if(m_nPosition<0){
		if(m_tCurrent.Width==-3 || m_tCurrent.Precision==-3){
			m_tCurrent=m_Placeholder[m_nIndex];
		}

		//check if read arguments from input data
		if(m_tCurrent.Width==-1){
			m_tCurrent.Width=(int)n;
			if(m_tCurrent.Width<=0) m_tCurrent.Width=-2;
		}else if(m_tCurrent.Precision==-1){
			m_tCurrent.Precision=(int)n;
			if(m_tCurrent.Precision<0) m_tCurrent.Precision=-2;
		}else{
			appendByPosition(m_nIndex,n,bSigned);

			m_nIndex++;
			m_tCurrent.Width=-3;
			m_tCurrent.Precision=-3;
		}
	}else{
		int ppp=(++m_nPosition),idx=m;

		for(int i=m_nIndex;i<m;i++){
			int p=m_Placeholder[i].Position;

			if(p==ppp){
				m_tCurrent=m_Placeholder[i];
				appendByPosition(i,n,bSigned);
			}else if(p>ppp && i<idx){
				idx=i;
			}
		}

		m_nIndex=idx;
	}
}

void MyFormat::append(double n){
	int m=m_Placeholder.size();
	if(m_nIndex>=m) return;

	if(m_nPosition<0){
		if(m_tCurrent.Width==-3 || m_tCurrent.Precision==-3){
			m_tCurrent=m_Placeholder[m_nIndex];
		}

		//check if read arguments from input data
		if(m_tCurrent.Width==-1){
			m_tCurrent.Width=(int)n;
			if(m_tCurrent.Width<=0) m_tCurrent.Width=-2;
		}else if(m_tCurrent.Precision==-1){
			m_tCurrent.Precision=(int)n;
			if(m_tCurrent.Precision<0) m_tCurrent.Precision=-2;
		}else{
			appendByPosition(m_nIndex,n);

			m_nIndex++;
			m_tCurrent.Width=-3;
			m_tCurrent.Precision=-3;
		}
	}else{
		int ppp=(++m_nPosition),idx=m;

		for(int i=m_nIndex;i<m;i++){
			int p=m_Placeholder[i].Position;

			if(p==ppp){
				m_tCurrent=m_Placeholder[i];
				appendByPosition(i,n);
			}else if(p>ppp && i<idx){
				idx=i;
			}
		}

		m_nIndex=idx;
	}
}

void MyFormat::append(const u8string& s){
	int m=m_Placeholder.size();
	if(m_nIndex>=m) return;

	if(m_nPosition<0){
		if(m_tCurrent.Width==-3 || m_tCurrent.Precision==-3){
			m_tCurrent=m_Placeholder[m_nIndex];
		}

		//check if read arguments from input data
		if(m_tCurrent.Width==-1){
			m_tCurrent.Width=-2;
		}else if(m_tCurrent.Precision==-1){
			m_tCurrent.Precision=-2;
		}else{
			appendByPosition(m_nIndex,s);

			m_nIndex++;
			m_tCurrent.Width=-3;
			m_tCurrent.Precision=-3;
		}
	}else{
		int ppp=(++m_nPosition),idx=m;

		for(int i=m_nIndex;i<m;i++){
			int p=m_Placeholder[i].Position;

			if(p==ppp){
				m_tCurrent=m_Placeholder[i];
				appendByPosition(i,s);
			}else if(p>ppp && i<idx){
				idx=i;
			}
		}

		m_nIndex=idx;
	}
}

void MyFormat::append(const void* lp){
#if SIZEOF_VOIDP==4
	append((int32_t)(intptr_t)lp);
#elif SIZEOF_VOIDP==8
	append((int64_t)(intptr_t)lp);
#else
	//FIXME: Unknown pointer size! e.g. Raspberry Pi (?)
	if((intptr_t)(void*)(-1)==(intptr_t)(void*)(0xFFFFFFFFUL)){
		append((int32_t)(intptr_t)lp);
	}else{
		append((int64_t)(intptr_t)lp);
	}
#endif
}

void MyFormat::append(const char* lp){
	int m=m_Placeholder.size();
	if(m_nIndex>=m) return;

	if(m_nPosition<0){
		if(m_tCurrent.Width==-3 || m_tCurrent.Precision==-3){
			m_tCurrent=m_Placeholder[m_nIndex];
		}

		//check if read arguments from input data
		if(m_tCurrent.Width==-1){
			m_tCurrent.Width=(int)(intptr_t)lp;
			if(m_tCurrent.Width<=0) m_tCurrent.Width=-2;
		}else if(m_tCurrent.Precision==-1){
			m_tCurrent.Precision=(int)(intptr_t)lp;
			if(m_tCurrent.Precision<0) m_tCurrent.Precision=-2;
		}else{
			appendByPosition(m_nIndex,lp);

			m_nIndex++;
			m_tCurrent.Width=-3;
			m_tCurrent.Precision=-3;
		}
	}else{
		int ppp=(++m_nPosition),idx=m;

		for(int i=m_nIndex;i<m;i++){
			int p=m_Placeholder[i].Position;

			if(p==ppp){
				m_tCurrent=m_Placeholder[i];
				appendByPosition(i,lp);
			}else if(p>ppp && i<idx){
				idx=i;
			}
		}

		m_nIndex=idx;
	}
}

template<class T,class UT>
void MyFormat::appendIntegerByPosition(int index,T n,bool bSigned){
	switch(m_tCurrent.Type){
	case 'd':
	case 'x': case 'X': case 'o': case 'p':
	case 'c':
		break;
	case 'i':
		bSigned=true;
		break;
	case 'u':
		bSigned=false;
		break;
	case 'e': case 'E': case 'f': case 'F': case 'g': case 'G': case 'a': case 'A':
		appendByPosition(index,bSigned?(double)n:(double)(unsigned int)n);
		return;
		break;
	case 's':
		if(n==0){
			appendByPosition(index,"(null)");
			return;
			break;
		}
		//fall-through
	default:
		rawAppendByPosition(index,"(error)");
		return;
		break;
	}

	if(m_tCurrent.Type=='p'){
		m_tCurrent.Type='X';
		m_tCurrent.Precision=sizeof(T)*2;
	}

	//append
	if(index>=(int)m_sFormattedString.size()){
		for(int i=index-m_sFormattedString.size();i>=0;i--){
			m_sFormattedString.push_back(u8string());
		}
	}

	u8string& str=m_sFormattedString[index];
	str.clear();

	//print
	int length=0;

	switch(m_tCurrent.Type){
	case 'x': case 'X':
	case 'o':
		{
			//get value
			if(m_tCurrent.Type=='o'){
				UT nn=n;
				do{
					m_sBuffer[63-(length++)]='0'+(nn & 0x7);
					nn>>=3;
				}while(nn);
			}else{
				const char* lut=m_tCurrent.Type=='X'?"0123456789ABCDEF":"0123456789abcdef";
				UT nn=n;
				do{
					m_sBuffer[63-(length++)]=lut[nn & 0xF];
					nn>>=4;
				}while(nn);
			}

			if(m_tCurrent.Precision>=0){
				//calc size
				if(n==0 && m_tCurrent.Precision==0) length=0;
				else if(length>m_tCurrent.Precision) m_tCurrent.Precision=length;

				int padCount=m_tCurrent.Width-m_tCurrent.Precision;

				if((m_tCurrent.Flags & MyFormatFlags::Alternate) && n){
					if(m_tCurrent.Type=='o') padCount--;
					else padCount-=2;
				}

				//print
				if(padCount>0 && (m_tCurrent.Flags & MyFormatFlags::HasMinus)==0){
					str.append(padCount,' ');
				}

				if((m_tCurrent.Flags & MyFormatFlags::Alternate) && n){
					str.push_back('0');
					if(m_tCurrent.Type!='o') str.push_back(m_tCurrent.Type);
				}

				if(m_tCurrent.Precision>length){
					str.append(m_tCurrent.Precision-length,'0');
				}

				str.append(m_sBuffer+64-length,m_sBuffer+64);

				if(padCount>0 && (m_tCurrent.Flags & MyFormatFlags::HasMinus)){
					str.append(padCount,' ');
				}
			}else{
				//calc size
				int padCount=m_tCurrent.Width-length;

				if((m_tCurrent.Flags & MyFormatFlags::Alternate) && n){
					if(m_tCurrent.Type=='o') padCount--;
					else padCount-=2;
				}

				//print
				if(padCount>0 && (m_tCurrent.Flags & (MyFormatFlags::HasMinus | MyFormatFlags::HasZero))==0){
					str.append(padCount,' ');
				}

				if((m_tCurrent.Flags & MyFormatFlags::Alternate) && n){
					str.push_back('0');
					if(m_tCurrent.Type!='o') str.push_back(m_tCurrent.Type);
				}

				if(padCount>0 && (m_tCurrent.Flags & MyFormatFlags::HasZero)){
					str.append(padCount,'0');
				}

				str.append(m_sBuffer+64-length,m_sBuffer+64);

				if(padCount>0 && (m_tCurrent.Flags & MyFormatFlags::HasMinus)){
					str.append(padCount,' ');
				}
			}
		}
		break;
	case 'c':
		{
			int c=(int)n;

			if(c<0) c&=0xFFFF;
			else if(c>=0x110000) c='?';

			U8_ENCODE(c,m_sBuffer[length++]=);

			int padCount=m_tCurrent.Width-length;

			if(padCount>0 && (m_tCurrent.Flags & MyFormatFlags::HasMinus)==0){
				str.append(padCount,(m_tCurrent.Flags & MyFormatFlags::HasZero)?'0':' ');
			}

			str.append(m_sBuffer,m_sBuffer+length);

			if(padCount>0 && (m_tCurrent.Flags & MyFormatFlags::HasMinus)){
				str.append(padCount,' ');
			}
		}
		break;
	default:
		//decimal output
		{
			UT nn=n;
			char sign=(m_tCurrent.Flags & MyFormatFlags::HasPlus)?'+':(m_tCurrent.Flags & MyFormatFlags::HasSpace)?' ':0;

			const char* lut=
				"00010203040506070809"
				"10111213141516171819"
				"20212223242526272829"
				"30313233343536373839"
				"40414243444546474849"
				"50515253545556575859"
				"60616263646566676869"
				"70717273747576777879"
				"80818283848586878889"
				"90919293949596979899";

			if(bSigned && n<0){
				nn=-n;
				sign='-';
			}

			do{
				int n2=int(nn % UT(100));
				nn/=UT(100);

				if(nn==0 && n2<10){
					m_sBuffer[63-(length++)]='0'+n2;
				}else{
					m_sBuffer[62-length]=lut[n2*2];
					m_sBuffer[63-length]=lut[n2*2+1];
					length+=2;
				}
			}while(nn);

			if(m_tCurrent.Precision>=0){
				//calc size
				if(n==0 && m_tCurrent.Precision==0) length=0;
				else if(length>m_tCurrent.Precision) m_tCurrent.Precision=length;

				int padCount=m_tCurrent.Width-m_tCurrent.Precision;

				if(m_tCurrent.Flags & MyFormatFlags::HasThousandSeparator) padCount-=(m_tCurrent.Precision-1)/3;
				if(sign) padCount--;

				//print
				if(padCount>0 && (m_tCurrent.Flags & MyFormatFlags::HasMinus)==0){
					str.append(padCount,' ');
				}

				if(sign) str.push_back(sign);

				if(m_tCurrent.Flags & MyFormatFlags::HasThousandSeparator){
					for(int i=m_tCurrent.Precision-1;i>=0;i--){
						str.push_back(i<length?m_sBuffer[63-i]:'0');
						if(i>0 && i%3==0) str.push_back(',');
					}
				}else{
					if(m_tCurrent.Precision>length){
						str.append(m_tCurrent.Precision-length,'0');
					}
					str.append(m_sBuffer+64-length,m_sBuffer+64);
				}

				if(padCount>0 && (m_tCurrent.Flags & MyFormatFlags::HasMinus)){
					str.append(padCount,' ');
				}
			}else{
				//calc size
				int padCount=m_tCurrent.Width-length;

				if(m_tCurrent.Flags & MyFormatFlags::HasThousandSeparator) padCount-=(length-1)/3;
				if(sign) padCount--;

				//print
				if(padCount>0 && (m_tCurrent.Flags & (MyFormatFlags::HasMinus | MyFormatFlags::HasZero))==0){
					str.append(padCount,' ');
				}

				if(sign) str.push_back(sign);

				//FIXME: thousand separator in 0s
				if(padCount>0 && (m_tCurrent.Flags & MyFormatFlags::HasZero)){
					str.append(padCount,'0');
				}

				if(m_tCurrent.Flags & MyFormatFlags::HasThousandSeparator){
					for(int i=length-1;i>=0;i--){
						str.push_back(m_sBuffer[63-i]);
						if(i>0 && i%3==0) str.push_back(',');
					}
				}else{
					str.append(m_sBuffer+64-length,m_sBuffer+64);
				}

				if(padCount>0 && (m_tCurrent.Flags & MyFormatFlags::HasMinus)){
					str.append(padCount,' ');
				}
			}
		}
		break;
	}
}

void MyFormat::appendByPosition(int index,int32_t n,bool bSigned){
	appendIntegerByPosition<int32_t,uint32_t>(index,n,bSigned);
}

void MyFormat::appendByPosition(int index,int64_t n,bool bSigned){
	appendIntegerByPosition<int64_t,uint64_t>(index,n,bSigned);
}

void MyFormat::appendByPosition(int index,double n){
	switch(m_tCurrent.Type){
	case 'd': case 'i':
	case 'x': case 'X': case 'o': case 'p':
		appendByPosition(index,(int64_t)n,true);
		return;
		break;
	case 'u':
		appendByPosition(index,(int64_t)(uint64_t)n,false);
		return;
		break;
	case 'e': case 'E': case 'f': case 'F': case 'g': case 'G': case 'a': case 'A':
		break;
	case 'c':
		appendByPosition(index,(int)n,true);
		return;
		break;
	case 's':
		if(n==0.0){
			appendByPosition(index,"(null)");
			return;
			break;
		}
		//fall-through
	default:
		rawAppendByPosition(index,"(error)");
		return;
		break;
	}

	//FIXME: dirty workaround
	if(m_tCurrent.Width>1000) m_tCurrent.Width=1000;
	if(m_tCurrent.Precision>512) m_tCurrent.Precision=512;

	//create format string
	char buf[32];
	char *lp=buf;

	*(lp++)='%';

	if(m_tCurrent.Flags & MyFormatFlags::HasPlus) *(lp++)='+';
	else if(m_tCurrent.Flags & MyFormatFlags::HasSpace) *(lp++)=' ';

	if(m_tCurrent.Flags & MyFormatFlags::HasMinus) *(lp++)='-';
	else if(m_tCurrent.Flags & MyFormatFlags::HasZero) *(lp++)='0';

	if(m_tCurrent.Flags & MyFormatFlags::Alternate) *(lp++)='#';

	if(m_tCurrent.Width>0) lp+=sprintf(lp,"%d",m_tCurrent.Width);
	if(m_tCurrent.Precision>=0) lp+=sprintf(lp,".%d",m_tCurrent.Precision);

	*(lp++)=m_tCurrent.Type;
	*(lp++)=0;

	//print
	sprintf(m_sBuffer,buf,n);

	//append
	if(index<(int)m_sFormattedString.size()){
		m_sFormattedString[index].assign(m_sBuffer);
	}else{
		for(int i=index-m_sFormattedString.size();i>0;i--){
			m_sFormattedString.push_back(u8string());
		}
		m_sFormattedString.push_back(m_sBuffer);
	}

	//add thousand separator (experimental)
	//FIXME: bad width and precision when thousand separator enabled
	if(m_tCurrent.Flags & MyFormatFlags::HasThousandSeparator){
		u8string& str=m_sFormattedString[index];

		int m=str.size(),lps,i;
		char c=0;

		for(lps=0;lps<m;lps++){
			c=str[lps];
			if(c>'0' && c<'9') break;
		}

		for(i=lps;i<m;i++){
			c=str[i];
			if(c<'0' || c>'9') break;
		}

		if(c!='e' && c!='E'){
			for(i-=3;i>lps;i-=3){
				str.insert(str.begin()+i,',');
			}
		}
	}
}

void MyFormat::appendByPosition(int index,const u8string& s){
	if(m_tCurrent.Type!='s'){
		rawAppendByPosition(index,"(error)");
		return;
	}

	//append
	if(index>=(int)m_sFormattedString.size()){
		for(int i=index-m_sFormattedString.size();i>=0;i--){
			m_sFormattedString.push_back(u8string());
		}
	}

	u8string& str=m_sFormattedString[index];
	str.clear();

	//calc size
	int length=s.size();
	if(m_tCurrent.Precision>=0 && length>m_tCurrent.Precision) length=m_tCurrent.Precision;
	int padCount=m_tCurrent.Width-length;

	if(padCount>0 && (m_tCurrent.Flags & MyFormatFlags::HasMinus)==0){
		str.append(padCount,(m_tCurrent.Flags & MyFormatFlags::HasZero)?'0':' ');
	}

	str.append(s.begin(),s.begin()+length);

	if(padCount>0 && (m_tCurrent.Flags & MyFormatFlags::HasMinus)){
		str.append(padCount,' ');
	}
}

void MyFormat::appendByPosition(int index,const char* lp){
	switch(m_tCurrent.Type){
	case 'd': case 'i':
	case 'x': case 'X': case 'o': case 'p':
	case 'c':
#if SIZEOF_VOIDP==4
		appendByPosition(index,(int32_t)(intptr_t)lp,true);
#elif SIZEOF_VOIDP==8
		appendByPosition(index,(int64_t)(intptr_t)lp,true);
#else
		//FIXME: Unknown pointer size! e.g. Raspberry Pi (?)
		if((intptr_t)(void*)(-1)==(intptr_t)(void*)(0xFFFFFFFFUL)){
			appendByPosition(index,(int32_t)(intptr_t)lp,true);
		}else{
			appendByPosition(index,(int64_t)(intptr_t)lp,true);
		}
#endif
		return;
		break;
	case 'u':
#if SIZEOF_VOIDP==4
		appendByPosition(index,(int32_t)(intptr_t)lp,false);
#elif SIZEOF_VOIDP==8
		appendByPosition(index,(int64_t)(intptr_t)lp,false);
#else
		//FIXME: Unknown pointer size! e.g. Raspberry Pi (?)
		if((intptr_t)(void*)(-1)==(intptr_t)(void*)(0xFFFFFFFFUL)){
			appendByPosition(index,(int32_t)(intptr_t)lp,false);
		}else{
			appendByPosition(index,(int64_t)(intptr_t)lp,false);
		}
#endif
		return;
		break;
	case 'e': case 'E': case 'f': case 'F': case 'g': case 'G': case 'a': case 'A':
		appendByPosition(index,(double)(intptr_t)lp);
		return;
		break;
	case 's':
		break;
	default:
		rawAppendByPosition(index,"(error)");
		return;
		break;
	}

	if(lp==NULL) lp="(null)";

	//append
	if(index>=(int)m_sFormattedString.size()){
		for(int i=index-m_sFormattedString.size();i>=0;i--){
			m_sFormattedString.push_back(u8string());
		}
	}

	u8string& str=m_sFormattedString[index];
	str.clear();

	//calc size
	int length=strlen(lp);
	if(m_tCurrent.Precision>=0 && length>m_tCurrent.Precision) length=m_tCurrent.Precision;
	int padCount=m_tCurrent.Width-length;

	if(padCount>0 && (m_tCurrent.Flags & MyFormatFlags::HasMinus)==0){
		str.append(padCount,(m_tCurrent.Flags & MyFormatFlags::HasZero)?'0':' ');
	}

	str.append(lp,lp+length);

	if(padCount>0 && (m_tCurrent.Flags & MyFormatFlags::HasMinus)){
		str.append(padCount,' ');
	}
}

void MyFormat::rawAppendByPosition(int index,const char* lp){
	if(index<(int)m_sFormattedString.size()){
		m_sFormattedString[index].assign(lp);
	}else{
		for(int i=index-m_sFormattedString.size();i>0;i--){
			m_sFormattedString.push_back(u8string());
		}
		m_sFormattedString.push_back(lp);
	}
}

const u8string& MyFormat::str() const{
	if(m_bDirty){
		int m=m_Placeholder.size();
		if(m>0){
			int lps=m_Placeholder[0].nStart;
			m_sReturn.assign(m_sFormat.begin(),m_sFormat.begin()+lps);

			for(int i=0;i<m;i++){
				if(i<(int)m_sFormattedString.size()) m_sReturn.append(m_sFormattedString[i]);
				if(i<m-1){
					int lpe=m_Placeholder[i+1].nStart;
					m_sReturn.append(m_sFormat.begin()+lps,m_sFormat.begin()+lpe);
					lps=lpe;
				}else{
					m_sReturn.append(m_sFormat.begin()+lps,m_sFormat.end());
				}
			}
		}else{
			m_sReturn=m_sFormat;
		}

		m_bDirty=false;
	}

	return m_sReturn;
}

void MyFormat::appendFormat(const u8string& fmt){
	int m=fmt.size();

	if(m==0) return;

	m_bDirty=true;

	for(int i=0;i<m;i++){
		char c=fmt[i];

		if(c=='%'){
			MyFormatPlaceholder t={0,0,0,-3,-2,m_sFormat.size()};

			//check first number
			if((++i)>=m) return;
			c=fmt[i];
			if(c>='1' && c<='9'){
				int num=c-'0';
				for(;;){
					if((++i)>=m) return;
					c=fmt[i];
					if(c<'0' || c>'9') break;
					num=num*10+(c-'0');
				}
				if(c=='$'){
					//position
					if((++i)>=m) return;
					if(num>0) t.Position=num;
				}else{
					//width
					if(num>0) t.Width=num;
					else t.Width=-2;
				}
			}

			if(t.Width==-3){
				//check flags
				for(;;){
					c=fmt[i];

					if(c=='+') t.Flags|=MyFormatFlags::HasPlus;
					else if(c==' ') t.Flags|=MyFormatFlags::HasSpace;
					else if(c=='-') t.Flags|=MyFormatFlags::HasMinus;
					else if(c=='#') t.Flags|=MyFormatFlags::Alternate;
					else if(c=='0') t.Flags|=MyFormatFlags::HasZero;
					else if(c=='\'') t.Flags|=MyFormatFlags::HasThousandSeparator;
					else break;

					if((++i)>=m) return;
				}

				if(t.Flags & MyFormatFlags::HasPlus) t.Flags&=~MyFormatFlags::HasSpace;
				if(t.Flags & MyFormatFlags::HasMinus) t.Flags&=~MyFormatFlags::HasZero;

				//check width
				c=fmt[i];
				if(c>='0' && c<='9'){
					int num=c-'0';
					for(;;){
						if((++i)>=m) return;
						c=fmt[i];
						if(c<'0' || c>'9') break;
						num=num*10+(c-'0');
					}

					if(num>0) t.Width=num;
					else t.Width=-2;
				}else if(c=='*'){
					if((++i)>=m) return;
					t.Width=-1;
				}else{
					t.Width=-2;
				}
			}

			//check precision
			if(fmt[i]=='.'){
				t.Precision=0;

				if((++i)>=m) return;
				c=fmt[i];
				if(c>='0' && c<='9'){
					int num=c-'0';
					for(;;){
						if((++i)>=m) return;
						c=fmt[i];
						if(c<'0' || c>'9') break;
						num=num*10+(c-'0');
					}

					if(num>=0) t.Precision=num;
				}else if(c=='*'){
					if((++i)>=m) return;
					t.Width=-1;
				}
			}

			assert(t.Width!=-3 && t.Precision!=-3);

			//check type
			t.Type=fmt[i];
			switch(t.Type){
			case 'd': case 'i': case 'u': case 'x': case 'X': case 'o': case 'p':
			case 'e': case 'E': case 'f': case 'F': case 'g': case 'G': case 'a': case 'A':
			case 'c': case 's':
				if(t.Position>0){
					if(m_Placeholder.empty()){
						m_nPosition=0;
					}else if(m_nPosition<0){
						t.Position=0;
					}
				}else{
					if(m_Placeholder.empty()){
						m_nPosition=-1;
					}else if(m_nPosition>=0){
						t.Position=m_Placeholder.size()+1;
						if(t.Width==-1) t.Width=-2;
						if(t.Precision==-1) t.Precision=-2;
					}
				}
				m_Placeholder.push_back(t);
				break;
			case '%':
				m_sFormat.push_back('%');
				break;
			default:
				break;
			}
		}else{
			m_sFormat.push_back(c);
		}
	}
}

void MyFormat::clear(){
	m_sFormat.clear();
	m_sReturn.clear();
	m_Placeholder.clear();
	m_sFormattedString.clear();
	m_nIndex=0;
	m_nPosition=0;
	m_tCurrent.Width=-3;
	m_tCurrent.Precision=-3;
	m_bDirty=false;
}

void MyFormat::restart(){
	m_sReturn.clear();
	m_sFormattedString.clear();
	m_nIndex=0;
	if(m_nPosition>0) m_nPosition=0;
	m_tCurrent.Width=-3;
	m_tCurrent.Precision=-3;
	m_bDirty=true;
}
