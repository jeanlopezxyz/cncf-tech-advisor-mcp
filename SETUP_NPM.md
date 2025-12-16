# Configurar NPM Token para Publicación Automática

## 1. Crear Token en NPM

1. Ve a https://www.npmjs.com/settings/jeanlopezxyz/tokens
2. Haz clic en **"Generate New Token"**
3. Selecciona el tipo **"Automation"**
4. Dale un nombre: "mcp-cncf-tech-advisor-ci"
5. No selecciones ningún paquete específico (acceso a todos)
6. Haz clic en **"Generate Token"**
7. **Copia el token inmediatamente** - no podrás verlo de nuevo

## 2. Configurar Secret en GitHub

1. Ve al repositorio: https://github.com/jeanlopezxyz/cncf-tech-advisor-mcp
2. Haz clic en **Settings**
3. En el menú lateral, ve a **Secrets and variables → Actions**
4. Haz clic en **"New repository secret"**
5. **Name**: `NPM_TOKEN`
6. **Secret**: [pega el token que copiaste]
7. Haz clic en **"Add secret"**

## 3. Verificar Configuración

El workflow está configurado para usar este secret en el paso de publicación:

```yaml
- name: Publish platform packages
  env:
    NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```

## 4. Probar la Publicación

Una vez configurado el token, puedes probar con:

```bash
# Crear un tag de prueba
git tag v1.0.0-test
git push origin v1.0.0-test

# O ejecutar manualmente el workflow desde GitHub UI
```

## 5. Si tienes 2FA en NPM

Si usas autenticación de dos factores en NPM, el token de Automation debería funcionar sin necesidad de OTP. Si tienes problemas, puedes:

1. Desactivar 2FA temporalmente para la prueba
2. O usar un token con mayores permisos

## Troubleshooting

### Error: "You must be a package owner"
- Asegúrate de que tu usuario NPM (jeanlopezxyz) tiene permisos de owner
- Verifica que los paquetes no existan ya con otro owner

### Error: "401 Unauthorized"
- Verifica que el token sea correcto
- Asegúrate que el tipo de token sea "Automation"

### Error: "403 Forbidden"
- Verifica permisos del paquete
- Revisa que el token tenga acceso de escritura