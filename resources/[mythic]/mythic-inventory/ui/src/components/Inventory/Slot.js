import React, { useState, useEffect } from 'react';
import { CircularProgress, LinearProgress, Popover } from '@mui/material';
import { makeStyles } from '@mui/styles';
import { connect, useDispatch, useSelector } from 'react-redux';

import { mergeSlot, moveSlot, swapSlot } from './actions';
import { getItemImage, getItemLabel } from './item';
import Nui from '../../util/Nui';
import { useSound } from '../../hooks';
import Tooltip from './Tooltip';
import { FormatThousands } from '../../util/Parser';

const useStyles = makeStyles((theme) => ({
	slotWrap: {
		display: "inline-block",
		margin: 3,
		opacity: "1",
		boxSizing: "border-box",
		flexGrow: 0,
		width: 125,
		flexBasis: 125,
		zIndex: 1,
		transition: "transform 0.2s ease, opacity 0.2s ease",
		"&:hover": {
		  transform: "translateY(-2px)",
		},
	  },
	  slot: {
		width: "100%",
		height: 125,
		background: "rgba(18, 18, 28, 0.7)",
		border: `1px solid rgba(255, 255, 255, 0.05)`,
		position: "relative",
		zIndex: 2,
		borderRadius: 8,
		//backdropFilter: "blur(5px)",
		boxShadow: "0 4px 15px rgba(0, 0, 0, 0.15)",
		overflow: "hidden",
		"&:not(.disabled):not(.empty)": {
		  transition: "all ease-in 0.15s",
		  "&:hover": {
			boxShadow: "0 8px 20px rgba(0, 0, 0, 0.25)",
			border: `1px solid rgba(255, 255, 255, 0.1)`,
			background: "rgba(28, 28, 38, 0.8)",
		  },
		},
		"&.rarity-1": {
		  borderBottom: `2px solid ${theme.palette.rarities.rare1}`,
		},
		"&.rarity-2": {
		  borderBottom: `2px solid ${theme.palette.rarities.rare2}`,
		},
		"&.rarity-3": {
		  borderBottom: `2px solid ${theme.palette.rarities.rare3}`,
		},
		"&.rarity-4": {
		  borderBottom: `2px solid ${theme.palette.rarities.rare4}`,
		},
		"&.rarity-5": {
		  borderBottom: `2px solid ${theme.palette.rarities.rare5}`,
		},
		"&.disabled": {
		  opacity: 0.5,
		  filter: "grayscale(0.5)",
		},
		"&.empty": {
		  background: "rgba(18, 18, 28, 0.4)",
		  border: `1px dashed rgba(255, 255, 255, 0.05)`,
		},
	  },
	  slotDrag: {
		width: "100%",
		height: 125,
		position: "relative",
		zIndex: 2,
		opacity: 0.35,
		transition: "opacity ease-in 0.15s, border ease-in 0.15s",
	  },
	  img: {
		height: 125,
		width: "100%",
		zIndex: 3,
		backgroundSize: "55%",
		backgroundRepeat: "no-repeat",
		backgroundPosition: "center center",
		display: "flex",
		alignItems: "center",
		justifyContent: "center",
	  },
	  count: {
		top: 8,
		right: 8,
		position: "absolute",
		textAlign: "right",
		padding: "2px 6px",
		color: theme.palette.text.main,
		background: "rgba(0, 0, 0, 0.7)",
		borderRadius: 4,
		fontSize: 12,
		fontWeight: 600,
		zIndex: 4,
		boxShadow: "0 2px 4px rgba(0, 0, 0, 0.2)",
	  },
	  label: {
		bottom: 0,
		left: 0,
		position: "absolute",
		textAlign: "center",
		height: 30,
		lineHeight: "30px",
		fontSize: 13,
		fontWeight: 500,
		width: "100%",
		maxWidth: "100%",
		overflow: "hidden",
		whiteSpace: "nowrap",
		color: "white",
		background: "rgba(0, 0, 0, 0.7)",
		//backdropFilter: "blur(5px)",
		borderTop: "1px solid rgba(255, 255, 255, 0.05)",
		zIndex: 4,
	  },
	  equipped: {
		top: 8,
		left: 8,
		position: "absolute",
		padding: "2px 6px",
		color: theme.palette.success.main,
		background: "rgba(0, 0, 0, 0.7)",
		borderRadius: 4,
		fontSize: 11,
		fontWeight: 600,
		zIndex: 4,
		boxShadow: "0 2px 4px rgba(0, 0, 0, 0.2)",
	  },
	  hotkey: {
		top: 8,
		left: 8,
		position: "absolute",
		padding: "2px 8px",
		width: "auto",
		minWidth: 20,
		textAlign: "center",
		color: theme.palette.success.main,
		background: "rgba(0, 0, 0, 0.7)",
		borderRadius: 4,
		fontSize: 11,
		fontWeight: 600,
		zIndex: 4,
		boxShadow: "0 2px 4px rgba(0, 0, 0, 0.2)",
	  },
	  price: {
		top: 8,
		left: 8,
		position: "absolute",
		padding: "2px 6px",
		color: theme.palette.success.main,
		background: "rgba(0, 0, 0, 0.7)",
		borderRadius: 4,
		fontSize: 11,
		fontWeight: 600,
		zIndex: 4,
		boxShadow: "0 2px 4px rgba(0, 0, 0, 0.2)",
		"&::before": {
		  content: '"$"',
		  marginRight: 2,
		  color: theme.palette.text.main,
		},
		"& small": {
		  marginLeft: 5,
		  "&::before": {
			content: '"($"',
			color: theme.palette.text.alt,
		  },
		  "&::after": {
			content: '")"',
			color: theme.palette.text.alt,
		  },
		},
	  },
	  durability: {
		bottom: 30,
		left: 0,
		position: "absolute",
		width: "100%",
		maxWidth: "100%",
		overflow: "hidden",
		height: 3,
		background: "transparent",
		zIndex: 4,
	  },
	  broken: {
		background: theme.palette.text.alt,
	  },
	  progressbar: {
		transition: "none !important",
		height: 3,
	  },
	  popover: {
		pointerEvents: "none",
	  },
	  paper: {
		padding: 15,
		border: `1px solid rgba(255, 255, 255, 0.1)`,
		borderRadius: 8,
		//backdropFilter: "blur(10px)",
		background: "rgb(18, 18, 28, 0.95)",
		boxShadow: "0 10px 25px rgba(0, 0, 0, 0.3)",
		"&.rarity-1": {
		  borderLeft: `3px solid ${theme.palette.rarities.rare1}`,
		},
		"&.rarity-2": {
		  borderLeft: `3px solid ${theme.palette.rarities.rare2}`,
		},
		"&.rarity-3": {
		  borderLeft: `3px solid ${theme.palette.rarities.rare3}`,
		},
		"&.rarity-4": {
		  borderLeft: `3px solid ${theme.palette.rarities.rare4}`,
		},
		"&.rarity-5": {
		  borderLeft: `3px solid ${theme.palette.rarities.rare5}`,
		},
	  },
	  loader: {
		height: "fit-content",
		width: "fit-content",
		position: "absolute",
		top: 0,
		bottom: 0,
		left: 0,
		right: 0,
		margin: "auto",
	  },
}));

const lua2json = (lua) =>
	JSON.parse(
		lua
			.replace(/\[([^\[\]]+)\]\s*=/g, (s, k) => `${k} :`)
			.replace(/,(\s*)\}/gm, (s, k) => `${k}}`),
	);

export default connect()((props) => {
	const metadata = Boolean(props.data?.MetaData)
		? typeof props.data?.MetaData == 'string'
			? lua2json(props.data.MetaData)
			: props.data.MetaData
		: Object();

	const classes = useStyles();
	const hidden = useSelector((state) => state.app.hidden);
	const hover = useSelector((state) => state.inventory.hover);
	const hoverOrigin = useSelector((state) => state.inventory.hoverOrigin);
	const inUse = useSelector((state) => state.inventory.inUse);
	const showSecondary = useSelector((state) => state.inventory.showSecondary);
	const secondaryInventory = useSelector(
		(state) => state.inventory.secondary,
	);
	const playerInventory = useSelector((state) => state.inventory.player);
	const items = useSelector((state) => state.inventory.items);
	const itemData = useSelector((state) => state.inventory.items)[
		props?.data?.Name
	];
	const hoverData = useSelector((state) => state.inventory.items)[
		hover?.Name
	];
	const dispatch = useDispatch();
	const soundEffect = useSound();

	const calcDurability = () => {
		if (!Boolean(props?.data?.CreateDate) || !Boolean(itemData?.durability))
			null;
		return Math.ceil(
			100 -
				((Math.floor(Date.now() / 1000) - props?.data?.CreateDate) /
					itemData?.durability) *
					100,
		);
	};

	const isWeaponDisabled =
		props.shop &&
		itemData?.requiresLicense &&
		itemData?.type == 2 &&
		!playerInventory.isWeaponEligble;

	const isQualiDisabled =
		props.shop &&
		Boolean(itemData?.qualification) &&
		(!Boolean(playerInventory.qualifications) ||
			playerInventory.qualifications.filter(
				(q) => q == itemData?.qualification,
			).length == 0);

	const isOpenContainer =
		Boolean(props.data) &&
		itemData?.type == 10 &&
		secondaryInventory.owner == `container:${metadata?.Container}`;

	const durability = calcDurability();

	const [anchorEl, setAnchorEl] = useState(null);
	const open = Boolean(anchorEl);
	const tooltipOpen = (event) => {
		setAnchorEl(event.currentTarget);
	};

	const tooltipClose = () => {
		setAnchorEl(null);
	};

	const isUsable = () => {
		return (
			!Boolean(inUse) &&
			props.owner == playerInventory.owner &&
			items[props.data.Name].isUsable &&
			(!Boolean(items[props.data.Name].durability) ||
				props.data?.CreateDate + items[props.data.Name].durability >
					Date.now() / 1000)
		);
	};

	const moveItem = () => {
		if (
			hoverOrigin.slot !== props.slot ||
			hoverOrigin.owner !== props.owner ||
			hoverOrigin.invType !== props.invType
		) {
			if (isQualiDisabled || isWeaponDisabled || isOpenContainer) {
				return;
			}

			let origin;
			if (
				playerInventory.owner === hoverOrigin.owner &&
				playerInventory.invType == hoverOrigin.invType
			) {
				origin = 'player';
			} else {
				origin = 'secondary';
			}
			let destination;
			if (
				playerInventory.owner === props.owner &&
				playerInventory.invType == props.invType
			) {
				destination = 'player';
			} else {
				destination = 'secondary';
			}

			if (destination == 'secondary' && secondaryInventory.shop) {
				Nui.send('FrontEndSound', 'DISABLED');
				return;
			}

			if (
				destination == 'player' &&
				origin == 'secondary' &&
				secondaryInventory.shop &&
				Boolean(props?.data?.Name) &&
				hoverOrigin.Name != props.data.Name
			) {
				Nui.send('FrontEndSound', 'DISABLED');
				return;
			}

			soundEffect('drag');
			const payload = {
				origin: {
					...hover,
					isStackable: itemData?.isStackable,
				},
				destination: props.data,
				originSlot: hoverOrigin.slot,
				destSlot: props.slot,
				itemData: hoverData,
			};

			setAnchorEl(null);
			let isSplit = hoverOrigin.Count != hover.Count;
			if (origin === destination) {
				if (origin === 'player') {
					let destSlot = playerInventory.inventory.filter(
						(s) => Boolean(s) && s.Slot == props.slot,
					)[0];

					if (Boolean(destSlot)) {
						if (
							destSlot.Name == hover.Name &&
							destSlot.Count + hover.Count <=
								items[destSlot.Name].isStackable
						) {
							if (isSplit) {
								moveSlot(
									hoverOrigin.owner,
									props.owner,
									hoverOrigin.slot,
									props.slot,
									hoverOrigin.invType,
									props.invType,
									hoverOrigin.Name,
									hoverOrigin.Count,
									hover.Count,
									hoverOrigin.class,
									props.vehClass,
									hoverOrigin.model,
									props.vehModel,
									hoverOrigin.slotOverride,
									props.slotOverride,
									hoverOrigin.capacityOverride,
									props.capacityOverride,
									isSplit,
								);
								dispatch({
									type: 'SPLIT_ITEM_PLAYER_SAME',
									payload,
								});
							} else {
								mergeSlot(
									hoverOrigin.owner,
									props.owner,
									hoverOrigin.slot,
									props.slot,
									hoverOrigin.invType,
									props.invType,
									hoverOrigin.Name,
									hoverOrigin.Count,
									hover.Count,
									hoverOrigin.class,
									props.vehClass,
									hoverOrigin.model,
									props.vehModel,
									hoverOrigin.slotOverride,
									props.slotOverride,
									hoverOrigin.capacityOverride,
									props.capacityOverride,
								);
								dispatch({
									type: 'MERGE_ITEM_PLAYER_SAME',
									payload,
								});
							}
						} else {
							swapSlot(
								hoverOrigin.owner,
								props.owner,
								hoverOrigin.slot,
								props.slot,
								hoverOrigin.invType,
								props.invType,
								hoverOrigin.Name,
								hoverOrigin.Count,
								hover.Count,
								hoverOrigin.class,
								props.vehClass,
								hoverOrigin.model,
								props.vehModel,
								hoverOrigin.slotOverride,
								props.slotOverride,
								hoverOrigin.capacityOverride,
								props.capacityOverride,
							);
							dispatch({
								type: 'SWAP_ITEM_PLAYER_SAME',
								payload,
							});
						}
					} else {
						moveSlot(
							hoverOrigin.owner,
							props.owner,
							hoverOrigin.slot,
							props.slot,
							hoverOrigin.invType,
							props.invType,
							hoverOrigin.Name,
							hoverOrigin.Count,
							hover.Count,
							hoverOrigin.class,
							props.vehClass,
							hoverOrigin.model,
							props.vehModel,
							hoverOrigin.slotOverride,
							props.slotOverride,
							hoverOrigin.capacityOverride,
							props.capacityOverride,
							isSplit,
						);
						if (isSplit) {
							dispatch({
								type: 'SPLIT_ITEM_PLAYER_SAME',
								payload,
							});
						} else {
							dispatch({
								type: 'MOVE_ITEM_PLAYER_SAME',
								payload,
							});
						}
					}
				} else {
					let destSlot = secondaryInventory.inventory.filter(
						(s) => Boolean(s) && s.Slot == props.slot,
					)[0];

					if (Boolean(destSlot)) {
						if (
							destSlot.Name == hover.Name &&
							destSlot.Count + hover.Count <=
								items[destSlot.Name].isStackable
						) {
							if (isSplit) {
								moveSlot(
									hoverOrigin.owner,
									props.owner,
									hoverOrigin.slot,
									props.slot,
									hoverOrigin.invType,
									props.invType,
									hoverOrigin.Name,
									hoverOrigin.Count,
									hover.Count,
									hoverOrigin.class,
									props.vehClass,
									hoverOrigin.model,
									props.vehModel,
									hoverOrigin.slotOverride,
									props.slotOverride,
									hoverOrigin.capacityOverride,
									props.capacityOverride,
									isSplit,
								);
								dispatch({
									type: 'SPLIT_ITEM_SECONDARY_SAME',
									payload,
								});
							} else {
								mergeSlot(
									hoverOrigin.owner,
									props.owner,
									hoverOrigin.slot,
									props.slot,
									hoverOrigin.invType,
									props.invType,
									hoverOrigin.Name,
									hoverOrigin.Count,
									hover.Count,
									hoverOrigin.class,
									props.vehClass,
									hoverOrigin.model,
									props.vehModel,
									hoverOrigin.slotOverride,
									props.slotOverride,
									hoverOrigin.capacityOverride,
									props.capacityOverride,
								);
								dispatch({
									type: 'MERGE_ITEM_SECONDARY_SAME',
									payload,
								});
							}
						} else {
							swapSlot(
								hoverOrigin.owner,
								props.owner,
								hoverOrigin.slot,
								props.slot,
								hoverOrigin.invType,
								props.invType,
								hoverOrigin.Name,
								hoverOrigin.Count,
								hover.Count,
								hoverOrigin.class,
								props.vehClass,
								hoverOrigin.model,
								props.vehModel,
								hoverOrigin.slotOverride,
								props.slotOverride,
								hoverOrigin.capacityOverride,
								props.capacityOverride,
							);
							dispatch({
								type: 'SWAP_ITEM_SECONDARY_SAME',
								payload,
							});
						}
					} else {
						moveSlot(
							hoverOrigin.owner,
							props.owner,
							hoverOrigin.slot,
							props.slot,
							hoverOrigin.invType,
							props.invType,
							hoverOrigin.Name,
							hoverOrigin.Count,
							hover.Count,
							hoverOrigin.class,
							props.vehClass,
							hoverOrigin.model,
							props.vehModel,
							hoverOrigin.slotOverride,
							props.slotOverride,
							hoverOrigin.capacityOverride,
							props.capacityOverride,
							isSplit,
						);
						if (isSplit) {
							dispatch({
								type: 'SPLIT_ITEM_SECONDARY_SAME',
								payload,
							});
						} else {
							dispatch({
								type: 'MOVE_ITEM_SECONDARY_SAME',
								payload,
							});
						}
					}
				}
			} else {
				if (origin === 'player') {
					let destSlot = secondaryInventory.inventory.filter(
						(s) => Boolean(s) && s.Slot == props.slot,
					)[0];

					if (Boolean(destSlot)) {
						if (
							destSlot.Name == hover.Name &&
							destSlot.Count + hover.Count <=
								items[destSlot.Name].isStackable
						) {
							if (isSplit) {
								moveSlot(
									hoverOrigin.owner,
									props.owner,
									hoverOrigin.slot,
									props.slot,
									hoverOrigin.invType,
									props.invType,
									hoverOrigin.Name,
									hoverOrigin.Count,
									hover.Count,
									hoverOrigin.class,
									props.vehClass,
									hoverOrigin.model,
									props.vehModel,
									hoverOrigin.slotOverride,
									props.slotOverride,
									hoverOrigin.capacityOverride,
									props.capacityOverride,
									isSplit,
								);
								dispatch({
									type: 'SPLIT_ITEM_PLAYER_TO_SECONDARY',
									payload,
								});
							} else {
								mergeSlot(
									hoverOrigin.owner,
									props.owner,
									hoverOrigin.slot,
									props.slot,
									hoverOrigin.invType,
									props.invType,
									hoverOrigin.Name,
									hoverOrigin.Count,
									hover.Count,
									hoverOrigin.class,
									props.vehClass,
									hoverOrigin.model,
									props.vehModel,
									hoverOrigin.slotOverride,
									props.slotOverride,
									hoverOrigin.capacityOverride,
									props.capacityOverride,
								);
								dispatch({
									type: 'MERGE_ITEM_PLAYER_TO_SECONDARY',
									payload,
								});
							}
						} else if (!secondaryInventory.shop) {
							swapSlot(
								hoverOrigin.owner,
								props.owner,
								hoverOrigin.slot,
								props.slot,
								hoverOrigin.invType,
								props.invType,
								hoverOrigin.Name,
								hoverOrigin.Count,
								hover.Count,
								hoverOrigin.class,
								props.vehClass,
								hoverOrigin.model,
								props.vehModel,
								hoverOrigin.slotOverride,
								props.slotOverride,
								hoverOrigin.capacityOverride,
								props.capacityOverride,
							);
							dispatch({
								type: 'SWAP_ITEM_PLAYER_TO_SECONDARY',
								payload,
							});
						}
					} else {
						moveSlot(
							hoverOrigin.owner,
							props.owner,
							hoverOrigin.slot,
							props.slot,
							hoverOrigin.invType,
							props.invType,
							hoverOrigin.Name,
							hoverOrigin.Count,
							hover.Count,
							hoverOrigin.class,
							props.vehClass,
							hoverOrigin.model,
							props.vehModel,
							hoverOrigin.slotOverride,
							props.slotOverride,
							hoverOrigin.capacityOverride,
							props.capacityOverride,
							isSplit,
						);
						if (isSplit) {
							dispatch({
								type: 'SPLIT_ITEM_PLAYER_TO_SECONDARY',
								payload,
							});
						} else {
							dispatch({
								type: 'MOVE_ITEM_PLAYER_TO_SECONDARY',
								payload,
							});
						}
					}
				} else {
					let destSlot = playerInventory.inventory.filter(
						(s) => Boolean(s) && s.Slot == props.slot,
					)[0];

					if (Boolean(destSlot)) {
						if (
							destSlot.Name == hover.Name &&
							destSlot.Count + hover.Count <=
								items[destSlot.Name].isStackable
						) {
							if (isSplit) {
								moveSlot(
									hoverOrigin.owner,
									props.owner,
									hoverOrigin.slot,
									props.slot,
									hoverOrigin.invType,
									props.invType,
									hoverOrigin.Name,
									hoverOrigin.Count,
									hover.Count,
									hoverOrigin.class,
									props.vehClass,
									hoverOrigin.model,
									props.vehModel,
									hoverOrigin.slotOverride,
									props.slotOverride,
									hoverOrigin.capacityOverride,
									props.capacityOverride,
									isSplit,
								);
								dispatch({
									type: 'SPLIT_ITEM_SECONDARY_TO_PLAYER',
									payload,
								});
							} else {
								mergeSlot(
									hoverOrigin.owner,
									props.owner,
									hoverOrigin.slot,
									props.slot,
									hoverOrigin.invType,
									props.invType,
									hoverOrigin.Name,
									hoverOrigin.Count,
									hover.Count,
									hoverOrigin.class,
									props.vehClass,
									hoverOrigin.model,
									props.vehModel,
									hoverOrigin.slotOverride,
									props.slotOverride,
									hoverOrigin.capacityOverride,
									props.capacityOverride,
								);
								dispatch({
									type: 'MERGE_ITEM_SECONDARY_TO_PLAYER',
									payload,
								});
							}
						} else if (!secondaryInventory.shop) {
							swapSlot(
								hoverOrigin.owner,
								props.owner,
								hoverOrigin.slot,
								props.slot,
								hoverOrigin.invType,
								props.invType,
								hoverOrigin.Name,
								hoverOrigin.Count,
								hover.Count,
								hoverOrigin.class,
								props.vehClass,
								hoverOrigin.model,
								props.vehModel,
								hoverOrigin.slotOverride,
								props.slotOverride,
								hoverOrigin.capacityOverride,
								props.capacityOverride,
							);
							dispatch({
								type: 'SWAP_ITEM_SECONDARY_TO_PLAYER',
								payload,
							});
						}
					} else {
						moveSlot(
							hoverOrigin.owner,
							props.owner,
							hoverOrigin.slot,
							props.slot,
							hoverOrigin.invType,
							props.invType,
							hoverOrigin.Name,
							hoverOrigin.Count,
							hover.Count,
							hoverOrigin.class,
							props.vehClass,
							hoverOrigin.model,
							props.vehModel,
							hoverOrigin.slotOverride,
							props.slotOverride,
							hoverOrigin.capacityOverride,
							props.capacityOverride,
							isSplit,
						);
						if (isSplit) {
							dispatch({
								type: 'SPLIT_ITEM_SECONDARY_TO_PLAYER',
								payload,
							});
						} else {
							dispatch({
								type: 'MOVE_ITEM_SECONDARY_TO_PLAYER',
								payload,
							});
						}
					}
				}
			}
			setAnchorEl(null);
		}

		props.dispatch({
			type: 'SET_HOVER',
			payload: null,
		});
		props.dispatch({
			type: 'SET_HOVER_ORIGIN',
			payload: null,
		});
	};

	const onMouseDown = (event) => {
		event.preventDefault();
		if (props.locked) return;
		if (hoverOrigin == null) {
			if (!Boolean(props.data?.Name)) return;
			if (event.button !== 0 && event.button !== 1) return;

			if (isQualiDisabled || isWeaponDisabled || isOpenContainer) {
				Nui.send('FrontEndSound', 'DISABLED');
				return;
			}

			if (event.button === 1) {
				if (isUsable()) {
					props.onUse(props.owner, props.data.Slot, props.invType);
					dispatch({
						type: 'USE_ITEM_PLAYER',
						payload: {
							originSlot: props.data.Slot,
						},
					});
				} else {
					Nui.send('FrontEndSound', 'DISABLED');
					return;
				}
			} else {
				if (event.shiftKey && showSecondary) {
					let payload = {
						origin: {
							...props.data,
							slot: props.slot,
							owner: props.owner,
							invType: props.invType,
							shop: props.shop,
							isStackable: itemData.isStackable,
						},
						destination: Object(),
						originSlot: props.slot,
						itemData: itemData,
					};

					if (
						playerInventory.owner === props.owner &&
						playerInventory.invType === props.invType
					) {
						if (secondaryInventory.shop) {
							Nui.send('FrontEndSound', 'DISABLED');
							return;
						}

						secondaryInventory.inventory
							.filter((s) => Boolean(s))
							.sort((a, b) => a.Slot - b.Slot)
							.every((slot) => {
								if (
									slot.Name == props.data.Name &&
									Boolean(itemData.isStackable) &&
									props.data.Count + slot.Count <=
										itemData.isStackable &&
									(itemData.durability == null ||
										Math.abs(
											(props.data?.CreateDate ||
												Date.now() / 1000) -
												(slot?.CreateDate ||
													Date.now() / 1000),
										) <= 3600)
								) {
									payload.destination = slot;
									payload.destSlot = slot.Slot;
									return false;
								}
								return true;
							});

						if (!Boolean(payload.destSlot)) {
							for (let i = 1; i <= secondaryInventory.size; i++) {
								if (
									secondaryInventory.inventory.filter(
										(s) => Boolean(s) && s.Slot == i,
									).length == 0
								) {
									payload.destSlot = i;
									break;
								}
							}
						}

						if (Boolean(payload.destSlot)) {
							soundEffect('drag');

							if (
								secondaryInventory.inventory.filter(
									(s) =>
										Boolean(s) &&
										s.Slot == payload.destSlot,
								).length > 0
							) {
								mergeSlot(
									playerInventory.owner,
									secondaryInventory.owner,
									props.slot,
									payload.destSlot,
									props.invType,
									secondaryInventory.invType,
									props.data.Name,
									props.data.Count,
									props.data.Count,
									false,
									secondaryInventory.class,
									false,
									secondaryInventory.model,
									false,
									secondaryInventory.slotOverride,
									false,
									secondaryInventory.capacityOverride,
								);
								dispatch({
									type: 'MERGE_ITEM_PLAYER_TO_SECONDARY',
									payload,
								});
							} else {
								moveSlot(
									playerInventory.owner,
									secondaryInventory.owner,
									props.slot,
									payload.destSlot,
									props.invType,
									secondaryInventory.invType,
									props.data.Name,
									props.data.Count,
									props.data.Count,
									false,
									secondaryInventory.class,
									false,
									secondaryInventory.model,
									false,
									secondaryInventory.slotOverride,
									false,
									secondaryInventory.capacityOverride,
								);
								dispatch({
									type: 'MOVE_ITEM_PLAYER_TO_SECONDARY',
									payload,
								});
							}
							setAnchorEl(null);
						} else {
							Nui.send('FrontEndSound', 'DISABLED');
						}
					} else {
						playerInventory.inventory
							.filter((s) => Boolean(s))
							.sort((a, b) => a.Slot - b.Slot)
							.every((slot) => {
								if (
									slot.Name == props.data.Name &&
									Boolean(itemData.isStackable) &&
									props.data.Count + slot.Count <=
										itemData.isStackable &&
									(itemData.durability == null ||
										Math.abs(
											(props.data?.CreateDate ||
												Date.now() / 1000) -
												(slot?.CreateDate ||
													Date.now() / 1000),
										) <= 3600)
								) {
									payload.destination = slot;
									payload.destSlot = slot.Slot;
									return false;
								}
								return true;
							});

						if (!Boolean(payload.destSlot)) {
							for (let i = 1; i <= playerInventory.size; i++) {
								if (
									playerInventory.inventory.filter(
										(s) => Boolean(s) && s.Slot == i,
									).length == 0
								) {
									payload.destSlot = i;
									break;
								}
							}
						}

						if (Boolean(payload.destSlot)) {
							soundEffect('drag');

							if (
								playerInventory.inventory.filter(
									(s) =>
										Boolean(s) &&
										s.Slot == payload.destSlot,
								).length > 0
							) {
								mergeSlot(
									secondaryInventory.owner,
									playerInventory.owner,
									props.slot,
									payload.destSlot,
									props.invType,
									1,
									props.data.Name,
									props.data.Count,
									props.data.Count,
									secondaryInventory.class,
									false,
									secondaryInventory.model,
									false,
									secondaryInventory.slotOverride,
									false,
									secondaryInventory.capacityOverride,
									false,
								);
								dispatch({
									type: 'MERGE_ITEM_SECONDARY_TO_PLAYER',
									payload,
								});
							} else {
								moveSlot(
									secondaryInventory.owner,
									playerInventory.owner,
									props.slot,
									payload.destSlot,
									props.invType,
									1,
									props.data.Name,
									props.data.Count,
									props.data.Count,
									secondaryInventory.class,
									false,
									secondaryInventory.model,
									false,
									secondaryInventory.slotOverride,
									false,
									secondaryInventory.capacityOverride,
									false,
								);
								dispatch({
									type: 'MOVE_ITEM_SECONDARY_TO_PLAYER',
									payload,
								});
							}
							setAnchorEl(null);
						} else {
							Nui.send('FrontEndSound', 'DISABLED');
						}
					}
					setAnchorEl(null);
				} else if (event.ctrlKey) {
					props.dispatch({
						type: 'SET_HOVER',
						payload: {
							...props.data,
							Count: Math.ceil(props.data.Count / 2),
							slot: props.slot,
							owner: props.owner,
							shop: props.shop,
							free: props.free,
							invType: props.invType,
						},
					});
					props.dispatch({
						type: 'SET_HOVER_ORIGIN',
						payload: {
							...props.data,
							slot: props.slot,
							owner: props.owner,
							shop: props.shop,
							invType: props.invType,
							class: props.vehClass || false,
							model: props.vehModel || false,
						},
					});
					setAnchorEl(null);
				} else {
					props.dispatch({
						type: 'SET_HOVER',
						payload: {
							...props.data,
							slot: props.slot,
							owner: props.owner,
							shop: props.shop,
							free: props.free,
							invType: props.invType,
						},
					});
					props.dispatch({
						type: 'SET_HOVER_ORIGIN',
						payload: {
							...props.data,
							slot: props.slot,
							owner: props.owner,
							shop: props.shop,
							invType: props.invType,
							class: props.vehClass || false,
							model: props.vehModel || false,
						},
					});
					setAnchorEl(null);
				}
			}
		} else {
			moveItem();
		}
	};

	const onMouseUp = (event) => {
		if (props.locked) return;
		if (hoverOrigin == null) return;
		if (event.button !== 0) return;

		if (!event.shiftKey || !showSecondary) {
			moveItem();
		}
	};

	return (
		<div
			className={`${classes.slotWrap}${
				Boolean(props.equipped) ? ' equipped' : ''
			}${props.mini ? ' mini' : ''}`}
			onMouseDown={onMouseDown}
			onMouseUp={onMouseUp}
			onContextMenu={Boolean(itemData) ? props.onContextMenu : null}
			onMouseEnter={Boolean(itemData) ? tooltipOpen : null}
			onMouseLeave={Boolean(itemData) ? tooltipClose : null}
		>
			<div
				className={`${classes.slot}${props.mini ? ' mini' : ''}${
					props.solid ? ' solid' : ''
				} ${
					!Boolean(props.data?.Name)
						? ` empty`
						: ` rarity-${itemData.rarity}`
				}${
					hoverOrigin != null &&
					hoverOrigin.slot === props.slot &&
					hoverOrigin.owner === props.owner &&
					hoverOrigin.invType === props.invType
						? ` ${classes.slotDrag}`
						: ''
				}${
					isQualiDisabled || isWeaponDisabled || isOpenContainer
						? ' disabled'
						: ''
				}`}
			>
				{Boolean(itemData) && (
					<div
						className={`${classes.img}${props.mini ? ' mini' : ''}`}
						style={{
							backgroundImage: `url(${getItemImage(
								props.data,
								itemData,
							)})`,
						}}
					></div>
				)}
				{Boolean(itemData) && props.data.Count > 0 && (
					<div className={classes.count}>{props.data.Count}</div>
				)}
				{Boolean(props.equipped) ? (
					<div className={classes.equipped}>Equipped</div>
				) : props.hotkeys && props.slot <= 4 ? (
					<div className={classes.hotkey}>
						{Boolean(props.equipped) ? 'Equipped' : props.slot}
					</div>
				) : null}
				{props.shop &&
					Boolean(itemData) &&
					(props.free ? (
						<div className={classes.price}>FREE</div>
					) : (
						<div className={classes.price}>
							{FormatThousands(itemData.price * props.data.Count)}
							{props.data.Count > 1 && (
								<small>{FormatThousands(itemData.price)}</small>
							)}
						</div>
					))}
				{Boolean(itemData?.durability) &&
					Boolean(props?.data?.CreateDate) &&
					(durability > 0 ? (
						<LinearProgress
							className={classes.durability}
							color={
								durability >= 75
									? 'success'
									: durability >= 50
									? 'warning'
									: 'error'
							}
							classes={{
								determinate: classes.progressbar,
								bar: classes.progressbar,
								bar1: classes.progressbar,
							}}
							variant="determinate"
							value={durability}
						/>
					) : (
						<LinearProgress
							className={classes.durability}
							classes={{
								determinate: classes.broken,
								bar: classes.broken,
								bar1: classes.broken,
							}}
							variant="determinate"
							value={100}
						/>
					))}
				{Boolean(itemData) && (
					<div className={classes.label}>
						{getItemLabel(props.data, itemData)}
					</div>
				)}
				{Boolean(props.locked) && (
					<div className={classes.loader}>
						<CircularProgress color="inherit" size={30} />
					</div>
				)}
			</div>
			{Boolean(itemData) && (
				<Popover
					className={classes.popover}
					classes={{
						paper: `${classes.paper} rarity-${itemData.rarity}`,
					}}
					open={
						open && !Boolean(hover) && !hidden && Boolean(anchorEl)
					}
					anchorEl={anchorEl}
					anchorOrigin={{
						vertical: 'center',
						horizontal: 'right',
					}}
					transformOrigin={{
						vertical: 'top',
						horizontal: 'center',
					}}
					onClose={tooltipClose}
					disableRestoreFocus
				>
					<Tooltip
						isEligible={!isWeaponDisabled}
						isQualified={!isQualiDisabled}
						item={itemData}
						instance={props.data}
						durability={durability}
						invType={props.invType}
						shop={props.shop}
						free={props.free}
					/>
				</Popover>
			)}
		</div>
	);
});