"""
Unit tests — CounterpartyService (ownership + soft-delete).
"""

import pytest
from fastapi import HTTPException

from app.schemas.counterparty import CounterpartyCreate, CounterpartyUpdate
from app.services.counterparty import CounterpartyService
from tests.helpers import make_counterparty, make_user

pytestmark = pytest.mark.unit


def test_create_assigns_current_user(db_session):
    user = make_user(db_session)
    data = CounterpartyCreate(
        nombre="Ana López",
        banco="Bancolombia",
        numero_cuenta="998877",
    )

    item = CounterpartyService.create(db_session, user, data)

    assert item.id is not None
    assert item.user_id == user.id
    assert item.nombre == "Ana López"
    assert item.activo is True


def test_list_mine_only_own(db_session):
    owner = make_user(db_session, correo="a@x.com", usuario="owner")
    other = make_user(db_session, correo="b@x.com", usuario="other")
    mine = make_counterparty(db_session, owner, nombre="Mia")
    make_counterparty(db_session, other, nombre="Ajena")

    result = CounterpartyService.list_mine(db_session, owner)

    assert result.total == 1
    assert result.items[0].id == mine.id


def test_get_mine_404_foreign(db_session):
    owner = make_user(db_session, correo="a@x.com", usuario="owner")
    other = make_user(db_session, correo="b@x.com", usuario="other")
    foreign = make_counterparty(db_session, other)

    with pytest.raises(HTTPException) as exc:
        CounterpartyService.get_mine(db_session, owner, foreign.id)
    assert exc.value.status_code == 404


def test_deactivate_and_reactivate(db_session):
    user = make_user(db_session)
    item = make_counterparty(db_session, user)

    CounterpartyService.deactivate(db_session, user, item.id)
    db_session.refresh(item)
    assert item.activo is False

    listed = CounterpartyService.list_mine(db_session, user)
    assert listed.total == 0

    restored = CounterpartyService.reactivate(db_session, user, item.id)
    assert restored.activo is True


def test_update_rejects_inactive(db_session):
    user = make_user(db_session)
    item = make_counterparty(db_session, user)
    CounterpartyService.deactivate(db_session, user, item.id)

    with pytest.raises(HTTPException) as exc:
        CounterpartyService.update(
            db_session,
            user,
            item.id,
            CounterpartyUpdate(nombre="Nuevo"),
        )
    assert exc.value.status_code == 400
