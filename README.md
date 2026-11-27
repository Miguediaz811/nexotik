<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="img/nexotik-logo.svg?v=2">
    <source media="(prefers-color-scheme: light)" srcset="img/nexotik-logo-claro.svg?v=2">
    <img src="img/nexotik-logo-claro.svg?v=2" alt="Nexotik" width="420">
  </picture>
</p>

# Nexotik · Servicio Técnico de Computadores

*Tu tecnología, en buenas manos.*

Página web de Nexotik, servicio técnico: mantenimiento de computadores, Windows y Office, eliminación de virus, respaldo de información, instalación de cámaras WiFi y desarrollo de páginas web.

Contacto por WhatsApp: 321 875 7723

## Páginas

- `index.html`: página principal.
- `seguimiento.html`: el cliente consulta el estado de su orden con el número y el código (o con el QR de la orden impresa).
- `ordenes.html`: panel privado de órdenes, cuentas y ajustes (requiere iniciar sesión).

## Configurar Supabase (una sola vez)

1. En Supabase: **SQL Editor → New query**, pega todo `supabase/esquema.sql` y presiona **Run**.
2. **Authentication → Users → Add user → Create new user**: tu correo y una contraseña (marca *Auto Confirm User*).
3. **SQL Editor** otra vez, cambiando el correo por el tuyo:
   ```sql
   insert into public.admins (user_id)
   select id from auth.users where email = 'TU_CORREO_AQUI'
   on conflict do nothing;
   ```
4. **Authentication → Sign In / Providers → Email**: desactiva **Allow new users to sign up**, para que nadie más pueda crear cuentas.
5. **Project Settings → API**: copia la *Project URL* y la *anon public key* en `js/supabase-config.js`.
6. Abre `ordenes.html`, inicia sesión y acepta subir las órdenes que tenías guardadas en ese navegador.
