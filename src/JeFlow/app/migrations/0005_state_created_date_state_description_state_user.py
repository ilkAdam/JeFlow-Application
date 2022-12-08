# Generated by Django 4.1.2 on 2022-11-11 13:11

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('app', '0004_alter_state_name'),
    ]

    operations = [
        migrations.AddField(
            model_name='state',
            name='created_date',
            field=models.DateTimeField(auto_now_add=True, null=True, verbose_name='Oluşturulma Tarihi'),
        ),
        migrations.AddField(
            model_name='state',
            name='description',
            field=models.TextField(blank=True, null=True, verbose_name='Açıklama'),
        ),
        migrations.AddField(
            model_name='state',
            name='user',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.PROTECT, to=settings.AUTH_USER_MODEL, verbose_name='Kullanıcı'),
        ),
    ]