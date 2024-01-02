---
title: 记录一次jsp与servlet之间传递表单时遇到的问题
ZHtags: 
  - form
key: servlet-post
date: '2022-09-14'
lastmod: '2022-09-17'
---
*jsp提交表单时遇到一个问题，我需要提交两个表单，但是其中一个表单嵌套在另外一个表单中，尝试了嵌套表单，但是提交失败，servlet获取不到对应的参数于是尝试了js生成一个表单提交*
```html
<div class="body-content-list">
        <span class="input-name">电子邮件:</span>
        <input type="text" class="input-style" id="email" name="email" value="${requestScope.email}" placeholder="请填写电子邮箱地址" onchange="checkEmail()" onkeyup="value=value.replace(/[^\w\@\_\.]/ig,'')"/>
        <div id="chkEmail" style="font-size:12px;"></div>
      </div>
      <div class="body-content-list2">
        <span class="input-name">邮箱验证:</span>
        <input type="text" class="input-style" id="confirmId" name="confirmId" value="${requestScope.confirmId}" placeholder="请填写邮箱验证码"/>
        <div class="last-info">
          <span id="confirmEmail"><button type="button" class="btn btn-blue" id="confirm" style="min-width: 45px;text-align: center;font-size: 30px;background-color:#2a66e1;color: white;" onclick="sendEmail()">获取验证码</button></span>
        </div>
        <div id="chksend" style="font-size:12px;"></div>
      </div>
```
*注：button的type需要设置成button，阻止提交表单，鼠标点击事件执行js代码，requestScope用于获取servlet提交的参数。*  
```js
function sendEmail(){
    var email=document.getElementById("email").value;
    var universityId=document.getElementById("universityId").value;
    var Urole=document.getElementById("Urole").value;
    let form=document.createElement('form'); //创建表单
    form.action = "userServlet?action=sendEmail"; //跳转到servlet
    form.method = "POST"; //设置POST请求
    form.innerHTML = '<input name="email" value="'+email+'">'+'\n'+'<input name="universityId" value="'+universityId+'">'+'\n'+'<input name="Urole" value="'+Urole+'">'; //表单内容
    document.body.append(form);
    form.submit(); //提交表单
    document.getElementById("chksend").innerHTML="<font color=green>邮件发送成功</font>"; //设置邮件发送成功的说明
  }
```
```java
String email=req.getParameter("email"); //获取js提交的表单内容
String universityId=req.getParameter("universityId");
String Urole=req.getParameter("Urole");
req.setAttribute("username",universityId);
        req.setAttribute("email", email);
        req.setAttribute("Urole",Urole); //提交对应参数到jsp
        if(messageResponse == null){
            req.setAttribute("sendSuccess","-1"); //设置发送成功的标志
        }
        else{
            req.setAttribute("sendSuccess","0");
        }
        req.getRequestDispatcher("/regist.jsp").forward(req, resp); //跳转到jsp
```
*注：servlet使用getParameter函数获取表单内容，setAttribute函数提交对应参数。*