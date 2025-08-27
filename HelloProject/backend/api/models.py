from django.db import models


class Contributor(models.Model):
    name = models.CharField(max_length=200)
    email = models.EmailField(unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = "Contributor"
        verbose_name_plural = "Contributors"
        ordering = ['-created_at']
    
    def __str__(self):
        return self.name
