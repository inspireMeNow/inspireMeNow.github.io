---
title: mailgun收发邮件
ZHtags: 
  - mail
key: mailgun-setup
date: '2022-09-14'
lastmod: '2022-09-17'
---
*暑假小组合作做的项目[java-gradesystem](https://github.com/duan-dky/java-gradesystem)需要做邮箱验证，申请了mailgun帐号，准备用java实现一个发送邮件的功能*  
# 发送邮件
## 使用mailgun api
### java
```java
MailgunMessagesApi mailgunMessagesApi = MailgunClient.config(apikey)
                .createApi(MailgunMessagesApi.class);

        Message message = Message.builder()
                .from("STD成绩管理系统 <postmaster@yourdomain>")
                .to(email)
                .subject(subject)
                .text(post)
                .build();
        MessageResponse messageResponse = mailgunMessagesApi.sendMessage("yourdomain", message);
```
注：apikey和yourdomain填成自己的
### python
```python
def send_simple_message():
    return requests.post(
        "https://api.mailgun.net/v3/duan-dky.me/messages",
        auth=("api", "apikey"),
        data={"from": "postmaster@yourdomain",
              "to": ["mail@example.com", "postmaster@yourdomain"],
              "subject": subject,
              "text": post})
```
### javascript
```javascript
const apiKey = 'apikey';
const domain = 'yourdomain';

const mailgun = require('mailgun-js')({ domain, apiKey });

mailgun.
  messages().
  send({
    from: `test@${domain}`,
      to: email,
      subject: subject,
      text: post
  }).
  then(res => console.log(res)).
  catch(err => console.err(err));
```
**注意：此方法依赖mailgun-js模块**
## 使用smtp服务器发送
### java
```java
import java.io.*;
import java.net.InetAddress;
import java.util.Properties;
import java.util.Date;
import javax.mail.*;
import javax.mail.internet.*;
import com.sun.mail.smtp.*;

public class MGSendSimpleSMTP {

    public static void main(String args[]) throws Exception {

        Properties props = System.getProperties();
        props.put("mail.smtps.host", "smtp.mailgun.org");
        props.put("mail.smtps.auth", "true");

        Session session = Session.getInstance(props, null);
        Message msg = new MimeMessage(session);
        msg.setFrom(new InternetAddress("postmaster@yourdomain"));

        InternetAddress[] addrs = InternetAddress.parse("mail@example.com", false);
        msg.setRecipients(Message.RecipientType.TO, addrs);

        msg.setSubject(subject);
        msg.setText(post);
        msg.setSentDate(new Date());

        SMTPTransport t =
            (SMTPTransport) session.getTransport("smtps");
        t.connect("smtp.mailgun.org", "postmaster@yourdomain", "smtp_password");
        t.sendMessage(msg, msg.getAllRecipients());

        System.out.println("Response: " + t.getLastServerResponse());

        t.close();
    }
}
```
**注：我遇到了ssl错误问题，没有解决，此方法已弃用！**
### python
```python
import smtplib

from email.mime.text import MIMEText

msg = MIMEText(post)
msg['Subject'] = subject
msg['From']    = "postmaster@yourdomain"
msg['To']      = "mail@example.com"

s = smtplib.SMTP('smtp.mailgun.org', 587)

s.login('postmaster@yourdomain', 'smtp_password')
s.sendmail(msg['From'], msg['To'], msg.as_string())
s.quit()
```
# 接收邮件
*使用mailgun的route功能将接收的邮件转发到gmail*

