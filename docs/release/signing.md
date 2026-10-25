# 正式发布签名身份

2026-10-26，经维护者明确授权首次生成 RSA 4096 位 PKCS12 发布密钥，保存在仓库外并通过 Windows ACL 限制为当前用户与 SYSTEM 访问。四项 GitHub Actions Secrets 已配置；私钥及密码均不进入源码或发布资产。

正式证书 SHA-256：

```text
e65f1bd643af9093c491fe0880bb875c2d46a400e92a317b15f9eb527c694183
```

后续发布沿用该签名身份，并递增 build number。M7 的一次性测试证书不是此身份，也不用于公开发行。每批发布在 `build-metadata.json` 和 `release-notes.md` 中记录实际 APK 证书指纹。

本机保存了密钥、凭据及备份说明；维护者尚未确认独立介质备份。应把完整密钥目录备份到安全的独立存储，凭据文件属于秘密，不上传到仓库、Release 或聊天。
