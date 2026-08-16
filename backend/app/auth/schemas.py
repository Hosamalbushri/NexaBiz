from __future__ import annotations

from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class LoginRequest(BaseModel):
    model_config = ConfigDict(extra="ignore")

    email: str = Field(min_length=3, max_length=320)
    password: str = Field(min_length=1)
    company_id: UUID | None = None
    device_id: UUID | None = None
    device_name: str | None = None
    platform: str | None = None
    app_version: str | None = None


class RefreshRequest(BaseModel):
    model_config = ConfigDict(extra="ignore")

    refresh_token: str = Field(min_length=10)


class SwitchCompanyRequest(BaseModel):
    model_config = ConfigDict(extra="ignore")

    company_id: UUID


class DeviceRegisterRequest(BaseModel):
    model_config = ConfigDict(extra="ignore")

    device_id: UUID
    device_name: str = Field(min_length=1, max_length=200)
    platform: str = Field(default="unknown", max_length=64)
    app_version: str | None = Field(default=None, max_length=64)


class UserCreateRequest(BaseModel):
    model_config = ConfigDict(extra="ignore")

    name: str = Field(min_length=1, max_length=200)
    email: str = Field(min_length=3, max_length=320)
    password: str = Field(min_length=8, max_length=200)
    phone: str | None = None
    status: str = "active"
    company_id: UUID | None = None
    role_id: UUID | None = None
    is_super_admin: bool = False


class UserUpdateRequest(BaseModel):
    model_config = ConfigDict(extra="ignore")

    name: str | None = Field(default=None, min_length=1, max_length=200)
    phone: str | None = None
    status: str | None = None
    password: str | None = Field(default=None, min_length=8, max_length=200)


class UserStatusRequest(BaseModel):
    model_config = ConfigDict(extra="ignore")

    status: str = Field(pattern="^(active|inactive|suspended)$")


class RoleCreateRequest(BaseModel):
    model_config = ConfigDict(extra="ignore")

    name: str = Field(min_length=1, max_length=120)
    description: str | None = None
    permission_codes: list[str] = Field(default_factory=list)


class RoleUpdateRequest(BaseModel):
    model_config = ConfigDict(extra="ignore")

    name: str | None = Field(default=None, min_length=1, max_length=120)
    description: str | None = None
    permission_codes: list[str] | None = None


class CompanyCreateRequest(BaseModel):
    model_config = ConfigDict(extra="ignore")

    name: str = Field(min_length=1, max_length=200)
    code: str = Field(min_length=1, max_length=64)
    status: str = "active"


class CompanyUpdateRequest(BaseModel):
    model_config = ConfigDict(extra="ignore")

    name: str | None = Field(default=None, min_length=1, max_length=200)
    status: str | None = None


class CompanyMembershipRequest(BaseModel):
    model_config = ConfigDict(extra="ignore")

    user_id: UUID
    role_id: UUID | None = None
    status: str = "active"


class CompanyMembershipUpdateRequest(BaseModel):
    model_config = ConfigDict(extra="ignore")

    role_id: UUID | None = None
    status: str | None = None
